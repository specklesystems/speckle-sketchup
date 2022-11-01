# Copyright 2014-2021, Trimble Inc.
#
# License: The MIT License (MIT)

require "sketchup.rb"
require "stringio"

module Trimble
  module AttributeHelper

  PLUGIN = self

  class << self
    attr_reader :app_observer
    attr_reader :model_observer
    attr_reader :selection_observer
  end


  def self.visualize_selected
    content = self.traverse_selected
    html = self.wrap_content(content)

    options = {
      :dialog_title => "Attribute Visualizer",
      :preferences_key => 'AttributeVisualizer',
      :scrollable => true,
      :resizable => true,
      :height => 300,
      :width => 400,
      :left => 200,
      :top => 200
    }
    @window ||= UI::WebDialog.new(options)
    @window.set_html(html)
    @window.set_on_close {
      @window = nil
      self.detach_observers
    }
    unless @window.visible?
      @window.show
      self.attach_observers
    end
  end


  def self.attach_observers
    @app_observer ||= AppObserver.new
    @model_observer ||= ModelObserver.new
    @selection_observer ||= SelectionObserver.new
    model = Sketchup.active_model
    Sketchup.remove_observer(@app_observer)
    model.remove_observer(@model_observer)
    model.selection.remove_observer(@selection_observer)
    Sketchup.add_observer(@app_observer)
    model.add_observer(@model_observer)
    model.selection.add_observer(@selection_observer)
  end


  def self.detach_observers
    Sketchup.remove_observer(@app_observer)
    Sketchup.active_model.remove_observer(@model_observer)
    Sketchup.active_model.selection.remove_observer(@selection_observer)
  end


  def self.traverse_selected
    html = StringIO.new

    model = Sketchup.active_model
    selection = model.selection

    if selection.empty?
      if model.active_path.nil?
        entity = model
      else
        entity = model.active_path.last
      end
    else
      return "Invalid selection size" unless selection.size == 1
      entity = selection[0]
    end

    html.puts "<h1>#{self.escape_html(entity)}</h1>"
    if entity.respond_to?(:name)
      html.puts "<h2>#{self.escape_html(entity.name)}</h2>"
    end
    if entity.attribute_dictionaries
      entity.attribute_dictionaries.each { |dictionary|
        html.puts self.format_dictionary(dictionary)
      }
    else
      html.puts "No dictionaries"
    end

    if entity.is_a?(Sketchup::Group)
      definition = entity.entities.parent
    elsif entity.is_a?(Sketchup::ComponentInstance)
      definition = entity.definition
    else
      definition = nil
    end

    if definition && definition.attribute_dictionaries
      html.puts "<h1>#{self.escape_html(definition)}</h1>"
      html.puts "<h2>#{self.escape_html(definition.name)}</h2>"
      definition.attribute_dictionaries.each { |dictionary|
        html.puts self.format_dictionary(dictionary)
      }
    end

    html.string
  end


  def self.format_dictionary(dictionary, path = "")
    html_name = self.escape_html(dictionary.name)
    path = "#{path}:#{html_name}"
    html = StringIO.new
    html.puts "<table>"
    html.puts "<caption title='#{path}'>#{html_name}</caption>"
    html.puts "<tbody>"
    dictionary.each { |key, value|
      html_key = self.escape_html(key)
      html_value = self.escape_html(value)
      node_path = "#{path}:#{html_key}"
      html.puts "<tr title='#{node_path}'><td>#{html_key}</td><td>#{html_value}</td><td class='value_type'>#{value.class}</td></tr>"
    }
    if dictionary.attribute_dictionaries
      dictionary.attribute_dictionaries.each { |sub_dic|
        html.puts "<tr><td colspan='3' class='dictionary'>"
        html.puts self.format_dictionary(sub_dic, path)
        html.puts "</td></tr>"
      }
    end
    html.puts "</tbody>"
    html.puts "</table>"
    html.string
  end


  def self.escape_html(data)
    data.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end


  def self.wrap_content(content)
    html = <<-EOT
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<meta charset="UTF-8">
<style>
  html {
    font-family: "Calibri", sans-serif;
    font-size: 10pt;
  }
  h1 {
    font-size: 1.5em;
  }
  h2 {
    font-size: 1.2em;
  }
  table {
    width: 100%;
    /*padding: 0.5em;*/
    border: 1px solid #666;
  }
  caption {
    font-weight: bold;
    text-align: left;
    /*border-bottom: 1px solid silver;*/
    padding: 0.2em;
  }
  td {
    background: #f3f3f3;
    padding: 0.2em;
  }
  td.dictionary {
    background: none;
    padding-left: 1em;
  }
  tr:hover td {
    background: rgba(255,210,180,0.2);
  }
  .value_type {
    text-align: right;
    width: 5%;
  }
</style>
<head>
<body>
#{content}
</body>
</html>
    EOT
  end


  class SelectionObserver < Sketchup::SelectionObserver
    def onSelectionAdded(selection, element)
      selection_changed()
    end
    def onSelectionBulkChange(selection)
      selection_changed()
    end
    def onSelectionCleared(selection)
      selection_changed()
    end
    def onSelectionRemoved(selection, element)
      selection_changed()
    end

    private

    def selection_changed
      PLUGIN.visualize_selected
    end
  end # class SelectionObserver


  class ModelObserver < Sketchup::ModelObserver
    def onActivePathChanged(model)
      PLUGIN.visualize_selected
    end

    def onTransactionCommit(model)
      model_changed(model)
    end
    def onTransactionEmpty(model)
      model_changed(model)
    end
    def onTransactionRedo(model)
      model_changed(model)
    end
    def onTransactionUndo(model)
      model_changed(model)
    end

    private

    def model_changed(model)
      if @timer.nil?
        @timer = UI.start_timer(0.0, false) {
          @timer = nil
          PLUGIN.visualize_selected
        }
      end
    end
  end # class ModelObserver


  class AppObserver < Sketchup::AppObserver
    def onNewModel(model)
      observe_model(model)
    end
    def onOpenModel(model)
      observe_model(model)
    end

    private

    def observe_model(model)
      model.add_observer(PLUGIN.model_observer)
      model.selection.add_observer(PLUGIN.selection_observer)
      PLUGIN.visualize_selected
    end
  end # class AppObserver


  unless file_loaded?(__FILE__)
    command = UI::Command.new("Attribute Helper") { self.visualize_selected }
    command.status_bar_text = "Inspect and edit the attributes of a selection."

    menu_name = Sketchup.version.to_f < 21.1 ? 'Plugins' : 'Developer'
    menu = UI.menu(menu_name)
    menu.add_item(command)
    file_loaded(__FILE__)
  end


  end # module AttributeHelper
end # module Sketchup
