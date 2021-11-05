require "JSON"
require "json"
require "sketchup"
require "speckle_connector/converter/converter_sketchup"
require "speckle_connector/accounts"

module SpeckleSystems::SpeckleConnector
  UNITS = { 0 => "in", 1 => "ft", 2 => "mm", 3 => "cm", 4 => "m", 5 => "yd" }.freeze
  public_constant :UNITS

  def self.create_dialog
    options = {
      dialog_title: "SpeckleSketchUp",
      preferences_key: "example.htmldialog.materialinspector",
      style: UI::HtmlDialog::STYLE_DIALOG,
      min_width: 250,
      min_height: 50
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.center
    dialog
  end

  def self.show_dialog
    if @dialog&.visible?
      @dialog.bring_to_front
    else
      @dialog ||= create_dialog
      @dialog.add_action_callback("send_selection") do |_action_context, stream_id|
        send_selection(stream_id)
        nil
      end
      @dialog.add_action_callback("receive_objects") do |_action_context, base, stream_id|
        receive_objects(base, stream_id)
        nil
      end
      @dialog.add_action_callback("reload_accounts") do |_action_context|
        reload_accounts
      end

      @dialog.add_action_callback("init_local_accounts") do |_action_context|
        init_local_accounts

      end
      puts DEV_MODE
      if DEV_MODE
        @dialog.set_url("http://localhost:8081")
      else
        basedir = File.join(File.dirname(File.expand_path(__FILE__)), "html")
        html = File.read(File.join(basedir, "index.html"))
        @dialog.set_html(html)
      end

      @dialog.show

      @dialog
    end
  end

  def self.send_selection(stream_id)
    model = Sketchup.active_model
    converter = ConverterSketchup.new(UNITS[model.options["UnitsOptions"]["LengthUnit"]])
    converted = model.selection.map { |entity| converter.convert_to_speckle(entity) }
    puts("converted #{converted.count} objects for stream #{stream_id}")
    # puts(converted.to_json)
    @dialog.execute_script("convertedFromSketchup('#{stream_id}',#{converted.to_json})")
  rescue StandardError => e
    puts(e)
    @dialog.execute_script("sketchupOperationFailed('#{stream_id}')")
  end

  def self.receive_objects(base, stream_id)
    puts("received objects from stream #{stream_id}")
    model = Sketchup.active_model
    converter = ConverterSketchup.new(UNITS[model.options["UnitsOptions"]["LengthUnit"]])
    converter.traverse_commit_object(base)
    @dialog.execute_script("finishedReceiveInSketchup('#{stream_id}')")
  rescue StandardError => e
    puts(e)
    @dialog.execute_script("sketchupOperationFailed('#{stream_id}')")
  end

  def self.init_local_accounts
    @dialog.execute_script("loadAccounts(#{Accounts.load_accounts.to_json}, #{Accounts.get_suuid.to_json})")
  end

  def self.reload_accounts
    @dialog.execute_script("loadAccounts(#{Accounts.load_accounts.to_json})")
  end
end
