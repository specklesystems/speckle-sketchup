require "JSON"
require "json"
require "sketchup"
require "speckle_connector/converter/to_speckle"
require "speckle_connector/accounts"

module SpeckleSystems::SpeckleConnector
  UNITS = { 0 => "in", 1 => "ft", 2 => "mm", 3 => "cm", 4 => "m", 5 => "yd" }.freeze
  public_constant :UNITS

  def self.create_dialog
    options = {
      dialog_title: "Material",
      preferences_key: "example.htmldialog.materialinspector",
      style: UI::HtmlDialog::STYLE_DIALOG,
      url: "http://localhost:8081"
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.center
    dialog
  end

  def self.show_dialog
    if @dialog&.visible?
      @dialog.bring_to_front
    else
      # basedir = File.join(File.dirname(File.expand_path(__FILE__)), "html")
      # html = File.read(File.join(basedir, "index.html"))
      @dialog ||= create_dialog
      @dialog.add_action_callback("poke") do |action_context, name, num_pokes|
        on_poke(name, num_pokes)
        nil
      end
      @dialog.add_action_callback("send_selection") do |action_context, stream_id|
        send_selection(stream_id)
        nil
      end
      @dialog.add_action_callback('reload_accounts') do |action_context|
        reload_accounts()
      end
      # @dialog.set_html(html)
      @dialog.set_url("http://localhost:8081")
      @dialog.show
      reload_accounts()

      @dialog
    end
  end

  def self.on_poke(name, num_pokes)
    num_pokes.times do
      puts("Poke #{name}!")
    end
  end

  def self.send_selection(stream_id)
    model = Sketchup.active_model
    converter = ConverterSketchup.new(UNITS[model.options["UnitsOptions"]["LengthUnit"]])
    converted = model.selection.map { |entity| converter.convert_to_speckle(entity) }
    puts("converted #{converted.count} objects for stream #{stream_id}")
    # puts(converted.to_json)
    @dialog.execute_script("convertedFromSketchup('#{stream_id}',#{converted.to_json})")
  end

  def self.reload_accounts()
    @dialog.execute_script("loadAccounts(#{Accounts.load_accounts.to_json})")
  end

end
