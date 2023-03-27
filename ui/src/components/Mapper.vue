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
        <v-expansion-panel-content class="mx-n3">
          <v-data-table
              class="elevation-1"
              dense
              expand
              disable-filtering
              disable-pagination
              hide-default-footer
              item-key="entityType"
              :expanded.sync="expanded"
              :headers="selectionHeaders"
              :items="selectionTableData"
              :mobile-breakpoint="0"
          >
            <template v-slot:expanded-item="{ headers, item }">
              <td :colspan="headers.length" class="pl-2 pr-0">
                <v-data-table
                    v-model="selectedRows"
                    class="elevation-0 pa-0 ma-0"
                    dense
                    disable-filtering
                    disable-pagination
                    hide-default-footer
                    item-key="entityId"
                    :headers="subSelectionHeaders"
                    :items="item.entities"
                    :mobile-breakpoint="0"
                >
                  <template v-slot:item.isMapped="{ item }">
                    <v-icon :color="item.isMapped ? 'green' : 'red'">
                      {{ item.isMapped ? 'mdi-check-circle' : 'mdi-close-circle' }}
                    </v-icon>
                  </template>

                </v-data-table>
              </td>
            </template>
            <template v-slot:item.entityType="slotData">
              <div @click="clickColumn(slotData)">{{ slotData.item.entityType }}</div>
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
          <v-container v-if="entitySelected" class="btn-container pa-0">
            <v-card
                variant="outlined"
                class="pt-1 px-2 mb-6 mr-2"
                :color="entityCardColor"
                :width="entityCardWidth"
                @click="definitionSelected = false"
            >
              <v-card-title class="pa-0 pb-4">
                <v-icon class="mr-1">
                  {{getLastSelectedEntityIcon}}
                </v-icon>
                {{this.lastSelectedEntity["entityType"]}}
              </v-card-title>
              <v-card-subtitle class="pb-1 pr-0">
                Last selected entity
              </v-card-subtitle>
            </v-card>

            <v-card
                v-if=entityHasParent
                variant="outlined"
                class="pt-1 px-2 mb-6"
                :color="definitionSelected ? 'mappingEntity' : 'background2'"
                width="160px"
                @click="definitionSelected = true"
            >
              <v-card-title class="pa-0 pb-4">
                <v-icon class="mr-1">
                  mdi-atom
                </v-icon>
                {{"Definition"}}
              </v-card-title>
              <v-card-subtitle class="pb-1 pr-0">
                Instance definition
              </v-card-subtitle>
            </v-card>
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
              @click="applyMappings"
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
/*global sketchup*/
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
      expanded: [],
      selectedRows: [],
      definitionSelected: false,
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
        { text: 'Type', sortable: false, value: 'entityType', width: '60%' },
        { text: 'Count', sortable: false, align: 'center', value: 'count', width: '20%' },
        { text: 'Mapped', sortable: false, align: 'center', value: 'mappedCount', width: '20%' },
      ],
      subSelectionHeaders: [
        { text: 'Name/Id', sortable: false, value: 'nameOrId', width: '80%' },
        { text: 'Mapped', sortable: false, align: 'center', value: 'isMapped', width: '20%' },
      ],
      selectionTableData: []
    }
  },
  computed:{
    entityHasParent(){
      return this.lastSelectedEntity['entityType'] === 'Component' || this.lastSelectedEntity['entityType'] === 'Group'
    },
    entityCardWidth(){
      if (this.entityHasParent){
        return '160px'
      } else {
        return '330px'
      }
    },
    entityCardColor(){
      if (!this.entityHasParent){
        return 'background2'
      }
      return this.definitionSelected ? 'background2' : 'mappingEntity'
    },
    getLastSelectedEntityIcon(){
      const type = this.lastSelectedEntity['entityType']
      if (type === 'Face'){
        return 'mdi-vector-square'
      } else if (type === 'Edge'){
        return 'mdi-vector-polyline'
      } else if (type === 'Group'){
        return 'mdi-border-outside'
      } else if (type === 'Component'){
        return 'mdi-border-inside'
      } else {
        return 'mdi-close'
      }
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
      let groupByClass = groupBy('entityType')
      let groupedByWithKey = groupByClass(this.selectedEntities)
      this.selectionTableData = Object.entries(groupedByWithKey).map(
          (entry) => {
            const [className, entities] = entry
            return {
              'entityType': className,
              'entityIds': entities.map(entity => entity['entityId']),
              'count': entities !== true ? entities.length : 0,
              'entities': entities.map((entity) => {
                return {
                  'entityId': entity['entityId'],
                  'nameOrId': entity['name'] !== null ? entity['name'] : entity['entityId'],
                  'isMapped': entity['schema']['category'] !== undefined
                }
              }),
              'mappedCount': entities.filter((entity) => entity['schema']['category'] !== undefined).length
            }
          }
      )
    },
    clickColumn(slotData) {
      const indexExpanded = this.expanded.findIndex(i => i === slotData.item);
      if (indexExpanded > -1) {
        this.expanded.splice(indexExpanded, 1)
      } else {
        this.expanded.push(slotData.item);
      }
    },
    applyMappings(){
      const mapping = {
        entitiesToMap: this.selectedEntities.map((entity) => entity['entityId']),
        method: this.selectedMethod,
        category:  this.selectedCategory,
        name: this.name,
        isDefinition: this.definitionSelected
      }
      sketchup.exec({name: "apply_mappings", data: mapping})
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
  display: flex;
  flex-wrap: wrap;
}

.active .entity {
  border: 2px solid green;
}
</style>