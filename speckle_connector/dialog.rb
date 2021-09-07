require "JSON"
require "json"
require "sketchup"
require "speckle_connector/converter/to_speckle"

module SpeckleSystems::SpeckleConnector
  def self.create_dialog
    options = {
      dialog_title: "Material",
      preferences_key: "example.htmldialog.materialinspector",
      style: UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.center
    dialog
  end

  def self.show_dialog
    if @dialog&.visible?
      @dialog.bring_to_front
    else
      basedir = File.join(File.dirname(File.expand_path(__FILE__)), "html")
      html = File.read(File.join(basedir, "index.html"))
      @dialog ||= create_dialog
      @dialog.add_action_callback("poke") do |action_context, name, num_pokes|
        puts(action_context)
        on_poke(name, num_pokes)
        nil
      end
      @dialog.add_action_callback("send_selection") do |action_context|
        puts(action_context)
        send_selection
        nil
      end
      @dialog.set_html(html)
      @dialog.show

      @dialog
    end
  end

  def self.on_poke(name, num_pokes)
    num_pokes.times do
      puts("Poke #{name}!")
    end
    h = { "a" => 1, "s" => "string", "arr" => [1, 2, 3] }
    @dialog.execute_script("clickFromSettings(#{h.to_json})")
    @dialog.execute_script("clickFromMain(#{JSON.pretty_generate(h)})")
  end

  def self.send_selection()
    model = Sketchup.active_model
    converted = model.selection.each { |entity| ConverterSketchup.convert_to_speckle(entity) }
    @dialog.execute_script("convertedFromSketchup(#{converted.to_json})")
  end

  def self.get_selection
    model = Sketchup.active_model
    instances = model.selection.each { |entity| puts(entity) }
    h = { "a" => 1, "s" => "string", "arr" => [1, 2, 3] }
    @dialog.execute_script("clickFromSettings(#{h.to_json})")
    @dialog.execute_script("clickFromMain(#{JSON.pretty_generate(h)})")
  end
end
