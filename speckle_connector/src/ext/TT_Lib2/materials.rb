#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'
require_relative 'system.rb'

module SpeckleConnector
  # Collection of Material methods.
  #
  # @since 2.5.0
  module TT::Material

    # When the user clicks on a material in the materials browser
    # +model.materials.current+ will return a material that does not exist in the
    # model. It is possible to apply this material to entities in the model, but
    # it will evetually BugSplat.
    #
    # This method checks if a given material exist in the model and is safe to use.
    #
    # @param [Sketchup::Material] material
    # @param [Sketchup::Model] model
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.in_model?( material, model = Sketchup.active_model )
      #model.materials.any? { |m| m == material }
      # This is probably just as good to write. Is this wrapper method needed?
      model.materials.include?( material )
    end


    # Because SketchUp will bugsplat if a material selected from the library is
    # used this method attempts to add the material to the model.
    #
    # @note Do not use within a start_operation block. This method uses a
    #   temporary operation which will break any already initiated operations.
    #
    # @param [Sketchup::Model] model
    #
    # @return [Sketchup::Material]
    # @since 2.7.0
    def self.get_current( model = Sketchup.active_model )
      materials = model.materials
      m = materials.current
      return m if m.nil?
      # Check if material already exists. If it does - reuse it.
      name = m.name
      if x = materials[ name ]
        if x.color.to_i == m.color.to_i && x.alpha == m.alpha
          # No texture applied.
          if x.texture.nil? && m.texture.nil?
            materials.current = x
            return x
          end
          x_basename = File.basename( x.texture.filename )
          m_basename = File.basename( m.texture.filename )
          if m_basename == m.texture.filename
            # If the texture only have a filename - not a path.
            if x_basename == m.texture.filename &&
              x.texture.width == m.texture.width &&
              x.texture.height == m.texture.height
              materials.current = x
              return x
            end
          else
            # If the texture only have a filename with full path.
            if x.texture.filename == m.texture.filename &&
              x.texture.width == m.texture.width &&
              x.texture.height == m.texture.height
              materials.current = x
              return x
            end
          end
        else
        end
      end
      # Transfer name and colour.
      new_material = materials.add( name )
      new_material.color = m.color
      new_material.alpha = m.alpha
      # Any textures require special attention. If the filename contains a valid
      # path to an existing file nothing special needs to be done.
      #
      # But if the filename refers to a non-existing file it needs to be written
      # out to a temp file. This is where things become a bit risky and hacky.
      # Because TextureWriter doesn't accept Material objects the orphan material
      # needs to be temporarily applied to the model (risky).
      #
      # Materials from SketchUp's default library only contains the name of the
      # file without any paths. This is because the texture is located only within
      # the.skm.
      if m.texture
        filename = m.texture.filename
        if File.exist?( filename )
          new_material.texture = filename
        else
          # Create temp file to write the texture to.
          temp_path = TT::System.temp_path
          temp_folder = File.join( temp_path, 'tt_su_tmp_mtl' )
          temp_filename = File.basename( filename )
          temp_file = File.join( temp_folder, temp_filename )
          unless File.exist?( temp_folder )
            Dir.mkdir( temp_folder )
          end
          # Create temp group with the orphan material and write it out.
          #
          # Wrap within start_operation and clean up with abort_operation so it
          # doesn't end up in the undo stack.
          #
          # (!) This means this method should not occur within any other
          #     start_operation blocks - as operations cannot be nested.
          tw = Sketchup.create_texture_writer
          model.start_operation( 'Extract Orphan Material' ) # rubocop:disable SketchupPerformance/OperationDisableUI
          begin
            g = model.entities.add_group # rubocop:disable SketchupSuggestions/ModelEntities
            g.material = m
            tw.load( g )
            tw.write( g, temp_file )
          ensure
            model.abort_operation
          end
          # Load texture to material and clean up.
          new_material.texture = temp_file
          File.delete( temp_file )
        end
        new_material.texture.size = [ m.texture.width, m.texture.height ]
      end
      materials.current = new_material
      new_material
    end


    # Safely removes a material from a model.
    #
    # @param [Sketchup::Material] material
    # @param [Sketchup::Model] model
    #
    # @return [Boolean]
    # @since 2.5.0
    def self.remove( material, model = Sketchup.active_model )
      # SketchUp 8.0M1 introduced model.materials.remove, which turned out to be
      # bugged. It didn't remove the material from the entities in the model -
      # leaving the model with rouge invalid materials.
      # To work around this all entities are processed before the method is called.
      # The workaround for older versions also require this to be done.
      for e in model.entities # rubocop:disable SketchupSuggestions/ModelEntities
        e.material = nil if e.respond_to?( :material ) && e.material == material
        e.back_material = nil if e.respond_to?( :back_material ) && e.back_material == material
      end
      for d in model.definitions
        next if d.image?
        for e in d.entities
          e.material = nil if e.respond_to?( :material ) && e.material == material
          e.back_material = nil if e.respond_to?( :back_material ) && e.back_material == material
        end
      end
      materials = model.materials
      if materials.respond_to?( :remove )
        materials.remove( material )
      else
        # Workaround for SketchUp versions older than 8.0M1. Add all materials
        # except the one to be removed to temporary groups and purge the materials.
        temp_group = model.entities.add_group # rubocop:disable SketchupSuggestions/ModelEntities
        for m in model.materials
          next if m == material
          g = temp_group.add_group
          g.material = material
        end
        materials.purge_unused
        temp_group.erase!
        true
      end
    end

  end # module TT::Material
end
