module SpeckleSystems::SpeckleConnector
  class SpeckleEntityObserver < Sketchup::EntityObserver
    attr_accessor :registry

    def initialize
      super()
      @registry = Sketchup.active_model.attribute_dictionary("speckle_id_registry", true)
    end

    def onEraseEntity(entity)
      app_id = entity.get_attribute("speckle", "applicationId")
      return if app_id.nil?

      p(app_id)

      @registry.delete_key(app_id)

      p(@registry)
    end
  end
end