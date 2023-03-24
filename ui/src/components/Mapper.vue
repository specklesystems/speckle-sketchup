<template>
  <v-container fluid class="px-5 btn-container">
    <v-autocomplete
        label="Mapper Method"
        :disabled="!entitySelected"
        :items="['Direct Shape']"
        density="compact"
    ></v-autocomplete>

    <v-autocomplete
        :items="availableCategories"
        :disabled="!entitySelected"
        label="Category"
        density="compact"
    ></v-autocomplete>

    <v-text-field
        v-model="name"
        label="Name"
        :disabled="!entitySelected"
    ></v-text-field>

    <v-btn
        class="ma-2 pa-3"
        :disabled="!entitySelected"
    >
      <v-icon dark left>
        mdi-checkbox-marked-circle
      </v-icon>Apply Mappings
    </v-btn>
  </v-container>
</template>

<script>

import {bus} from "@/main";

global.entitySelected = function (selectionParameters) {
  bus.$emit('entities-selected', selectionParameters)
}

global.entitiesDeselected = function () {
  bus.$emit('entities-deselected')
}

export default {
  name: "Mapper",
  data() {
    return {
      entitySelected: false,
      selectedMethod: null,
      selectedCategory: null,
      selectedObjects: [],
      selectedObjectCount: null,
      name: "",
      enabledMethods: [],
      availableCategories: ["Floors", "Walls", "Windows"],
    }
  },
  methods:{
    clearInputs(){
      this.enabledMethods = []
      this.selectedObjects = []
      this.name = ""
    }
  },
  mounted() {
    bus.$on('entities-selected', async (selectionParameters) => {
      this.entitySelected = true
      const selectionParams = JSON.parse(selectionParameters)
      this.enabledMethods = selectionParams.enabledMethods
      this.selectedObjects = selectionParams.selectedObjects
      this.selectedObjectCount = this.selectedObjects.length
      this.entitySelected = this.selectedObjectCount !== 0
    })
    bus.$on('entities-deselected', async () => {
      this.entitySelected = false
      this.clearInputs()
    })
  }
}
</script>

<style scoped>
.btn-container{
  justify-content: center;
  display: flex;
  flex-wrap: wrap;
}
</style>