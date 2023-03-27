<template>
  <v-container fluid class="px-5 btn-container">

    <v-expansion-panels
      v-model="panel"
      accordion
      multiple
    >
      <v-expansion-panel key="selection">
        <v-expansion-panel-header>
          <div>
            <v-icon>
              {{ selectedEntityCount === 0 ? 'mdi-playlist-remove' : 'mdi-playlist-check' }}
            </v-icon>
            {{ `Selection (${selectedEntityCount})` }}
          </div>
        </v-expansion-panel-header>
        <v-expansion-panel-content>

          <v-data-table
              disable-filtering
              disable-pagination
              :headers="selectionHeaders"
              :items="selectionTableData"
              dense
              hide-default-footer
              class="elevation-1"
              :mobile-breakpoint="0"
          >
          </v-data-table>

        </v-expansion-panel-content>
      </v-expansion-panel>

      <v-expansion-panel key="mapping">
        <v-expansion-panel-header>
          <div>
            <v-icon>
              mdi-multiplication
            </v-icon>
            {{ `Mapping` }}
          </div>
        </v-expansion-panel-header>
        <v-expansion-panel-content>
          <v-autocomplete
              v-model="selectedMethod"
              class="pt-0"
              label="Mapper Method"
              :disabled="!entitySelected"
              :items="enabledMethods"
              density="compact"
          ></v-autocomplete>

          <v-autocomplete
              v-model="selectedCategory"
              class="pt-0"
              label="Category"
              :items="availableCategories"
              :disabled="!entitySelected"
              density="compact"
          ></v-autocomplete>

          <v-text-field
              v-model="name"
              class="pt-0"
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
        </v-expansion-panel-content>
      </v-expansion-panel>

      <v-expansion-panel key="mappedElements">
        <v-expansion-panel-header>
          <div>
            <v-icon>
              {{ mappedEntityCount === 0 ? 'mdi-playlist-remove' : 'mdi-playlist-check' }}
            </v-icon>
            {{ `Mapped Elements (${mappedEntityCount})` }}
          </div>
        </v-expansion-panel-header>
        <v-expansion-panel-content>
          {{"test"}}
        </v-expansion-panel-content>
      </v-expansion-panel>

    </v-expansion-panels>
  </v-container>
</template>

<script>

import {bus} from "@/main";
import {groupBy} from "@/utils/groupBy";

global.entitySelected = function (selectionParameters) {
  bus.$emit('entities-selected', JSON.stringify(selectionParameters))
}

global.entitiesDeselected = function () {
  bus.$emit('entities-deselected')
}

export default {
  name: "Mapper",
  data() {
    return {
      entitySelected: false,
      selectedEntityCount: 0,
      selectedEntities: [],
      selectedMethod: null,
      selectedCategory: null,
      name: "",
      enabledMethods: [],
      availableCategories: [],
      mappedEntityCount: 0,
      mappedEntities: [],
      panel: [1],
      selectionHeaders: [
        { text: 'Type', sortable: false, value: 'class', fixed: true, width: "80px" },
        { text: 'Count', sortable: false, value: 'count', fixed: true, width: "80px" },
      ],
      selectionTableData: []
    }
  },
  methods:{
    clearInputs(){
      this.enabledMethods = []
      this.availableCategories = []
      this.selectedEntities = []
      this.selectionTableData = []
      this.selectedEntityCount = 0
      this.name = ""
      this.selectedMethod = null
      this.selectedCategory = null
    },
    selectionTable(){
      let groupByClass = groupBy('class')
      let groupedByWithKey = groupByClass(this.selectedEntities)
      this.selectionTableData = Object.entries(groupedByWithKey).map(
          (entry) => {
            const [className, entities] = entry
            return {
              'class': className,
              'count': entities !== true ? entities.length : 0
            }
          }
      )
    }
  },
  mounted() {
    bus.$on('entities-selected', async (selectionParameters) => {
      this.entitySelected = true
      const selectionPars = JSON.parse(selectionParameters)
      this.enabledMethods = selectionPars.mappingMethods
      this.availableCategories = selectionPars.categories
      this.selectedEntities = selectionPars.selection
      this.selectedEntityCount = this.selectedEntities.length
      this.entitySelected = this.selectedEntityCount !== 0
      this.selectionTable()
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