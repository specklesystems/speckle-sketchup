<template>
  <!-- DIALOG: Settings -->
  <v-dialog v-model="showSettings">
    <template #activator="{ on, attrs }">
      <v-btn
          icon small class="mx-1"
          v-bind="attrs"
          v-on="on"
      >
        <v-icon>mdi-cog</v-icon>
      </v-btn>
    </template>

    <v-card>
      <v-card-title class="text-h5">
        Settings
      </v-card-title>
      <v-container class="px-6" pb-0>

        <!-- User preferences -->
        <div class="sm1 mt-3">User Preferences</div>
        <v-divider class="mb-2"/>

        <!-- Switch Theme -->
        <v-btn icon small class="mx-1" @click="switchTheme">
          <v-icon>mdi-theme-light-dark</v-icon>
        </v-btn>
        <span>Color Mode</span>

        <!-- FE2 -->
        <v-switch
            :input-value="fe2"
            class="pt-3 mt-n2 mb-n7"
            :label="'FE2'"
            @change="fe2Handler"
        />

        <!-- Register objects as Speckle Entity on send/receive -->
        <v-switch
            :input-value="registerSpeckleEntity"
            class="pt-3 mt-n2 mb-n7"
            :label="'Register objects as Speckle Entity on send/receive'"
            @change="registerSpeckleEntityHandler"
        />

        <!-- Switch Diffing -->
        <v-switch
            :input-value="diffing"
            class="pt-3 mt-n2 mb-n2"
            :label="'Diffing (Alpha)'"
            @change="diffingHandler"
        />

        <div class="sm1 mt-3">Model Preferences</div>
        <v-divider class="mb-2"/>
        <v-switch
            class="pt-1 mt-n2 mb-n2"
            :input-value="combineFacesByMaterial"
            :label="'Combine faces by material under mesh'"
            @change="combineFacesByMaterialHandler"
        />
        <v-switch
            :input-value="includeAttributes"
            class="pt-1 my-n5"
            :label="'Include entity attributes'"
            @change="includeAttributesHandler"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            :input-value="includeEdgeAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Edge'"
            :disabled="!includeAttributes"
            @change="includeEdgeAttributesHandler"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            :input-value="includeFaceAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Face'"
            :disabled="!includeAttributes"
            @change="includeFaceAttributesHandler"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            :input-value="includeGroupAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Group'"
            :disabled="!includeAttributes"
            @change="includeGroupAttributesHandler"
        />
        <v-icon class="ml-3" style="line-height: 0;">mdi-arrow-right-bottom</v-icon>
        <v-switch
            :input-value="includeComponentAttributes"
            class="pt-1 my-n5 ml-10"
            :label="'Component'"
            :disabled="!includeAttributes"
            @change="includeComponentAttributesHandler"
        />
        <v-switch
            :input-value="mergeCoplanarFaces"
            class="pt-1 mt-n2 mb-n2"
            :label="'Merge co-planar faces on receive'"
            @change="mergeCoplanarFacesHandler"
        />
      </v-container>

      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn
            color="blue darken-1"
            text
            @click="showSettings = false"
        >
          Close
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
/*global sketchup*/
import {bus} from "@/main";

export default {
  name: "ShowSettings",
  props: {
    preferences: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      showSettings: false,
      streamName: "",
      description: "",
      combineFacesByMaterial: this.preferences.model.combine_faces_by_material,
      includeAttributes: this.preferences.model.include_entity_attributes,
      includeFaceAttributes: this.preferences.model.include_face_entity_attributes,
      includeEdgeAttributes: this.preferences.model.include_edge_entity_attributes,
      includeGroupAttributes: this.preferences.model.include_group_entity_attributes,
      includeComponentAttributes: this.preferences.model.include_component_entity_attributes,
      mergeCoplanarFaces: this.preferences.model.merge_coplanar_faces,
      diffing: this.preferences.user.diffing,
      fe2: this.preferences.user.fe2,
      registerSpeckleEntity: this.preferences.user.register_speckle_entity
    }
  },
  watch: {
    'preferences': {
      handler(newValue) {
        this.combineFacesByMaterial = newValue.model.combine_faces_by_material
        this.includeAttributes = newValue.model.include_entity_attributes
        this.includeFaceAttributes = newValue.model.include_face_entity_attributes
        this.includeEdgeAttributes = newValue.model.include_edge_entity_attributes
        this.includeGroupAttributes = newValue.model.include_group_entity_attributes
        this.includeComponentAttributes = newValue.model.include_component_entity_attributes
        this.mergeCoplanarFaces = newValue.model.merge_coplanar_faces
        this.diffing = newValue.user.diffing
        this.fe2 = newValue.user.fe2
        this.registerSpeckleEntity = newValue.user.register_speckle_entity
      },
      deep: true,
      immediate: true
    },
    'showSettings': {
      handler(newValue) {
        if (newValue){
          this.$mixpanel.track('Connector Action', { name: 'Settings Open' })
        }
      }
    }
  },
  methods: {
    fe2Handler(newValue){
      this.fe2 = !!newValue
      sketchup.exec({
        name: "user_preferences_updated",
        data: {preference_hash: "configSketchup", preference: "fe2", value: this.fe2}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle FE2' })
      sketchup.exec({name: "collect_preferences", data: {}})
    },
    diffingHandler(newValue){
      this.diffing = !!newValue
      sketchup.exec({
        name: "user_preferences_updated",
        data: {preference_hash: "configSketchup", preference: "diffing", value: this.diffing}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Diffing' })
    },
    registerSpeckleEntityHandler(newValue){
      this.registerSpeckleEntity = !!newValue
      sketchup.exec({
        name: "user_preferences_updated",
        data: {preference_hash: "configSketchup", preference: "register_speckle_entity", value: this.registerSpeckleEntity}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Register Speckle Entity' })
    },
    combineFacesByMaterialHandler(newValue){
      this.combineFacesByMaterial = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "combine_faces_by_material", value: this.combineFacesByMaterial}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Combine Faces By Material' })
    },
    includeAttributesHandler(newValue){
      this.includeAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_entity_attributes", value: this.includeAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Include Entity Attributes' })
    },
    includeFaceAttributesHandler(newValue){
      this.includeFaceAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_face_entity_attributes", value: this.includeFaceAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Include Face Entity Attributes' })
    },
    includeEdgeAttributesHandler(newValue){
      this.includeEdgeAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_edge_entity_attributes", value: this.includeEdgeAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Include Edge Entity Attributes' })
    },
    includeGroupAttributesHandler(newValue){
      this.includeGroupAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_group_entity_attributes", value: this.includeGroupAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Include Group Entity Attributes' })
    },
    includeComponentAttributesHandler(newValue){
      this.includeComponentAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_component_entity_attributes", value: this.includeComponentAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Include Component Entity Attributes' })
    },
    mergeCoplanarFacesHandler(newValue){
      this.mergeCoplanarFaces = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "merge_coplanar_faces", value: this.mergeCoplanarFaces}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Merge Co-Planar Faces' })
    },
    switchTheme() {
      this.$vuetify.theme.dark = !this.$vuetify.theme.dark
      sketchup.exec({
        name: "user_preferences_updated",
        data: {preference_hash: "configSketchup", preference: "dark_theme", value: this.$vuetify.theme.dark}
      })
      this.$mixpanel.track('Connector Action', { name: 'Toggle Theme' })
    },
    refresh() {
      this.$apollo.queries.user.refetch()
      bus.$emit('refresh-streams')
    }
  }
}
</script>

<style>

</style>