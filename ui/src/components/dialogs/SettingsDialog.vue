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
        <!-- Switch Theme -->
        <div class="sm1 mt-3">User Preferences</div>
        <v-divider class="mb-2"/>
        <v-btn icon small class="mx-1" @click="switchTheme">
          <v-icon>mdi-theme-light-dark</v-icon>
        </v-btn>
        <span>Color Mode</span>

        <!-- Switch Diffing -->
        <v-switch
            :input-value="diffing"
            class="pt-3 mt-n2 mb-n2"
            :label="'Diffing (Alpha)'"
            @change="diffingHandler"
        />
        <div class="sm1 mt-3">Send Strategy</div>
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

        <div class="sm1 mt-3">Receive Strategy</div>
        <v-divider class="mb-2"/>
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
      diffing: this.preferences.user.diffing
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
      },
      deep: true,
      immediate: true
    },
    'showSettings': {
      handler(newValue) {
        if (newValue){
          this.$mixpanel.track('Connector Action', { name: 'Open Settings Dialog' })
        }
      }
    }
  },
  methods: {
    diffingHandler(newValue){
      this.diffing = !!newValue
      sketchup.exec({
        name: "user_preferences_updated",
        data: {preference_hash: "configSketchup", preference: "diffing", value: this.diffing}
      })
      this.$mixpanel.track('Connector Action', { name: 'Diffing' })
    },
    combineFacesByMaterialHandler(newValue){
      this.combineFacesByMaterial = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "combine_faces_by_material", value: this.combineFacesByMaterial}
      })
      this.$mixpanel.track('Connector Action', { name: 'Combine Faces By Material Option' })
    },
    includeAttributesHandler(newValue){
      this.includeAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_entity_attributes", value: this.includeAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Include Entity Attributes Option' })
    },
    includeFaceAttributesHandler(newValue){
      this.includeFaceAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_face_entity_attributes", value: this.includeFaceAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Include Face Entity Attributes Option' })
    },
    includeEdgeAttributesHandler(newValue){
      this.includeEdgeAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_edge_entity_attributes", value: this.includeEdgeAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Include Edge Entity Attributes Option' })
    },
    includeGroupAttributesHandler(newValue){
      this.includeGroupAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_group_entity_attributes", value: this.includeGroupAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Include Group Entity Attributes Option' })
    },
    includeComponentAttributesHandler(newValue){
      this.includeComponentAttributes = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "include_component_entity_attributes", value: this.includeComponentAttributes}
      })
      this.$mixpanel.track('Connector Action', { name: 'Include Component Entity Attributes Option' })
    },
    mergeCoplanarFacesHandler(newValue){
      this.mergeCoplanarFaces = !!newValue
      sketchup.exec({
        name: "model_preferences_updated",
        data: {preference: "merge_coplanar_faces", value: this.mergeCoplanarFaces}
      })
      this.$mixpanel.track('Connector Action', { name: 'Merge Co-Planar Faces Option' })
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