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
    if @dialog && @dialog.visible?
      @dialog.bring_to_front
    else
      basedir = File.join(File.dirname(File.expand_path(__FILE__)), 'html')
      html = File.read(File.join(basedir, 'index.html'))
      @dialog ||= self.create_dialog
      @dialog.add_action_callback('poke') { |action_context, name, num_pokes|
        self.on_poke(name, num_pokes)
        nil
      }
      @dialog.set_html(html)
      @dialog.show
    end
  end

  def self.on_poke(name, num_pokes)
    num_pokes.times {
      puts "Poke #{name}!"
    }
  end
end 
  