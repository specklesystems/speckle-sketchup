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
              :expanded.sync="selectionExpandedIndexes"
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
              <div @click="clickSelectionColumn(slotData)">{{ slotData.item.entityType }}</div>
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
          <v-container v-if="entitySelected" class="btn-container pa-0 mb-5">
            <v-card
                variant="outlined"
                class="pt-1 pl-2 mb-1 mr-2 v-alert--border flex"
                :elevation="entityCardElevation"
                :outlined="!definitionSelected"
                :width="entityCardWidth"
                @click="definitionSelectedHandler(false)"
            >
              <v-card-title class="pa-0 pb-3">
                <v-icon class="mr-1">
                  {{getLastSelectedEntityIcon}}
                </v-icon>
                {{this.lastSelectedEntity["entityType"]}}
              </v-card-title>
              <v-card-subtitle class="text-sm-subtitle-2 pb-1 pr-0 font-weight-light">
                Last selected entity
              </v-card-subtitle>
            </v-card>

            <v-card
                v-if=entityHasParent
                variant="outlined"
                :elevation="definitionSelected ? '6' : '1'"
                :outlined="definitionSelected"
                class="pt-1 pl-2 mb-1 mr-2 flex"
                width="160px"
                @click="definitionSelectedHandler(true)"
            >
              <v-card-title class="pa-0 pb-3">
                <v-icon class="mr-1">
                  mdi-atom
                </v-icon>
                {{"Definition"}}
              </v-card-title>
              <v-card-subtitle class="text-sm-subtitle-2 pb-1 pr-0 font-weight-light">
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
              item-value="value"
              item-text="key"
              :disabled="!entitySelected"
              density="compact"
          ></v-autocomplete>

          <v-text-field
              v-model="name"
              class="pt-0"
              label="Name"
              :disabled="!entitySelected"
          ></v-text-field>

          <v-container class="pa-0">
            <v-row justify="center" align="center">
              <v-col cols="auto" class="pa-1 pb-2">
                <v-btn
                    class="pt-1"
                    :disabled="!entitySelected"
                    @click="applyMapping"
                >
                  <v-icon dark left>
                    mdi-checkbox-marked-circle
                  </v-icon>Apply
                </v-btn>
              </v-col>
              <v-col cols="auto" class="pa-1 pb-2">
                <v-btn
                    class="pt-1"
                    :disabled="!entitySelected"
                    @click="clearMapping"
                >
                  <v-icon dark left>
                    mdi-close-circle
                  </v-icon>Clear
                </v-btn>
              </v-col>
            </v-row>


          </v-container>


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
          <v-data-table
              class="elevation-1"
              dense
              expand
              disable-filtering
              disable-pagination
              hide-default-footer
              item-key="categoryName"
              :expanded.sync="mappedElementsExpandedIndexes"
              :headers="mappedElementsHeaders"
              :items="mappedEntitiesTableData"
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
                    :headers="subMappedElementsHeaders"
                    :items="item.entities"
                    :mobile-breakpoint="0"
                >
                </v-data-table>
              </td>
            </template>
            <template v-slot:item.categoryName="slotData">
              <div @click="clickMappedElementsColumn(slotData)">{{ slotData.item.categoryName }}</div>
            </template>
          </v-data-table>
        </v-expansion-panel-content>
      </v-expansion-panel>

    </v-expansion-panels>

    <global-toast />
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

global.mappedEntitiesUpdated = function (mappedEntities) {
  bus.$emit('mapped-entities-updated', mappedEntities)
}

export default {
  name: "Mapper",
  components: {
    GlobalToast: () => import('@/components/GlobalToast')
  },
  data() {
    return {
      selectionExpandedIndexes: [],
      mappedElementsExpandedIndexes: [],
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
      mappedElementsHeaders: [
        { text: 'Category', sortable: false, value: 'categoryName', width: '80%' },
        { text: 'Count', sortable: false, align: 'center', value: 'count', width: '20%' }
      ],
      subMappedElementsHeaders: [
        { text: 'Type', sortable: false, value: 'entityType', width: '80%' },
        { text: 'Name/Id', sortable: false, align: 'center', value: 'nameOrId', width: '20%' },
      ],
      selectionTableData: [],
      mappedEntitiesTableData: [],
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
    entityCardElevation(){
      if (!this.entityHasParent){
        return '1'
      }
      return this.definitionSelected ? '1' : '6'
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
    getMappedElementsTableData(){
      let groupByCategoryName = groupBy('categoryName')
      let groupedByCategoryName = groupByCategoryName(this.mappedEntities)
      this.mappedEntitiesTableData = Object.entries(groupedByCategoryName).map(
          (entry) => {
            const [categoryName, entities] = entry
            return {
              'categoryName': categoryName,
              'count': entities !== true ? entities.length : 0,
              'entities': entities.map((entity) => {
                return {
                  'entityId': entity['entityId'],
                  'nameOrId': entity['name'] !== null ? entity['name'] : entity['entityId'],
                  'entityType': entity['entityType']
                }
              })
            }
          }
      )
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
    setInputValuesFromSelection(){
      if (!this.entitySelected){
        this.name = ""
        this.selectedMethod = null
        this.selectedCategory = null
        return
      }
      if (this.definitionSelected) {
        if (!this.isEntityDefinitionMapped(this.lastSelectedEntity)){
          this.name = ""
          this.selectedMethod = null
          this.selectedCategory = null
          return
        }
        this.selectedMethod = this.lastSelectedEntity['definitionSchema']['method']
        this.selectedCategory = this.lastSelectedEntity['definitionSchema']['category']
        this.name = this.lastSelectedEntity['definitionSchema']['name']
      } else {
        if (!this.isEntityMapped(this.lastSelectedEntity)){
          this.name = ""
          this.selectedMethod = null
          this.selectedCategory = null
          return
        }
        this.selectedMethod = this.lastSelectedEntity['schema']['method']
        this.selectedCategory = this.lastSelectedEntity['schema']['category']
        this.name = this.lastSelectedEntity['schema']['name']
      }

    },
    isEntityMapped(entity){
      return entity['schema']['category'] !== undefined
    },
    isEntityDefinitionMapped(entity){
      return entity['definitionSchema']['category'] !== undefined
    },
    definitionSelectedHandler(state){
      this.definitionSelected = state
      this.setInputValuesFromSelection()
    },
    clickSelectionColumn(slotData) {
      const indexExpanded = this.selectionExpandedIndexes.findIndex(i => i === slotData.item);
      if (indexExpanded > -1) {
        this.selectionExpandedIndexes.splice(indexExpanded, 1)
      } else {
        this.selectionExpandedIndexes.push(slotData.item);
      }
    },
    clickMappedElementsColumn(slotData) {
      const indexExpanded = this.mappedElementsExpandedIndexes.findIndex(i => i === slotData.item);
      if (indexExpanded > -1) {
        this.mappedElementsExpandedIndexes.splice(indexExpanded, 1)
      } else {
        this.mappedElementsExpandedIndexes.push(slotData.item);
      }
    },
    applyMapping(){
      if (this.selectedMethod === null || this.selectedCategory === null){
        this.$eventHub.$emit('error', {
          text: 'Method and category are not set.\n'
        })
        return
      }
      const mapping = {
        entitiesToMap: this.selectedEntities.map((entity) => entity['entityId']),
        method: this.selectedMethod,
        category:  this.selectedCategory,
        name: this.name,
        isDefinition: this.definitionSelected
      }
      sketchup.exec({name: "apply_mappings", data: mapping})
      this.$eventHub.$emit('success', {
        text: 'Mapping Applied.\n'
      })
    },
    clearMapping(){
      const mapping = {
        entitiesToClearMap: this.selectedEntities.map((entity) => entity['entityId']),
        isDefinition: this.definitionSelected
      }
      sketchup.exec({name: "clear_mappings", data: mapping})
      this.clearInputs()
      this.$eventHub.$emit('error', {
        text: 'Mapping Cleared.\n'
      })
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
      this.setInputValuesFromSelection()
    })
    bus.$on('entities-deselected', async () => {
      this.entitySelected = false
      this.clearInputs()
    })
    bus.$on('mapped-entities-updated', async (mappedEntities) => {
      this.mappedEntityCount = mappedEntities.length
      this.mappedEntities = mappedEntities
      this.getMappedElementsTableData()
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