<template>
  <v-container fluid class="px-3 btn-container">
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
              dense
              class="elevation-1"
              hide-default-footer
              :expand=true
              item-key="name"
              :headers="selectionHeaders"
              :items="selectionTableData"
              :mobile-breakpoint="0"
          >
            <template v-slot:items="props">
              <tr @click="props.expanded = !props.expanded">
                <td>{{ props.item.name }}</td>
                <td>{{ props.item.count }}</td>
              </tr>
            </template>

            <template v-slot:expand="props">
              <v-card flat>
                <v-card-text>{{ props.item.name }}</v-card-text>
              </v-card>
            </template>
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
          <v-container v-if=entitySelected class="pa-0 pb-3">
            <p class="text-h6 text-md-h5 text-lg-h4 pa-0 ma-0">
              {{this.lastSelectedEntity["entity_type"]}}
            </p>
            <p class="text-caption">
              Lastly selected object
            </p>
          </v-container>
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
      lastSelectedEntity: null,
      selectedMethod: null,
      selectedCategory: null,
      name: "",
      enabledMethods: [],
      availableCategories: [],
      mappedEntityCount: 0,
      mappedEntities: [],
      panel: [1],
      selectionHeaders: [
        { text: 'Type', sortable: false, value: 'name' },
        { text: 'Count', sortable: false, value: 'count' },
        { text: 'Mapped', sortable: false, value: 'mappedCount' },
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
    getSelectionTableData(){
      let groupByClass = groupBy('entity_type')
      let groupedByWithKey = groupByClass(this.selectedEntities)
      this.selectionTableData = Object.entries(groupedByWithKey).map(
          (entry) => {
            const [className, entities] = entry
            return {
              'name': className,
              'count': entities !== true ? entities.length : 0,
              'mappedCount': entities.filter((entity) => entity['schema']['category'] !== undefined).length
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
      this.lastSelectedEntity = this.selectedEntities[this.selectedEntities.length - 1]
      this.selectedEntityCount = this.selectedEntities.length
      this.entitySelected = this.selectedEntityCount !== 0
      this.getSelectionTableData()
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