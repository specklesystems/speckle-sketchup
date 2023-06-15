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

      <v-expansion-panel key="source">
        <v-expansion-panel-header class="flex">
          <v-container class="ma-0 pa-0">
            <v-icon>
              mdi-source-branch
            </v-icon>
            {{ `Source` }}
            <v-btn
                v-if="!sourceUpToDate"
                v-tooltip="'Source branch is not up-to-date!'"
                class="ma-0"
                height="20px"
                icon
                small
                color="red"
                @click="refreshSourceBranch"
            >
              <v-icon>
                mdi-update
              </v-icon>
            </v-btn>
          </v-container>
        </v-expansion-panel-header>
        <v-expansion-panel-content>
          <mapper-source :source-up-to-date="this.sourceUpToDate"/>
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
                class="pt-0 pl-2 mb-1 mr-2 flex"
                :elevation="entityCardElevation"
                :outlined="!definitionSelected"
                :width="entityCardWidth"
                min-width="150px"
                @click="definitionSelectedHandler(false)"
            >
              <v-card-title class="pa-0 pb-2">
                <v-icon class="mr-1 v-bottom-navigation--absolute">
                  {{ getSelectedEntityIcon }}
                </v-icon>
                {{getSelectedEntityText}}
                <v-spacer></v-spacer>
                <v-icon v-if="entityMapped" class="mr-n2 mt-n6" color="green">
                  mdi-checkbox-marked-circle
                </v-icon>
              </v-card-title>
              <v-card-subtitle class="pb-0 pr-0 font-weight-light">
                {{getSelectedEntitySubText}}
              </v-card-subtitle>
            </v-card>

            <v-card
                v-if=selectedEntitiesHasParent
                variant="outlined"
                class="pt-0 pl-2 mb-1 mr-2 flex"
                :elevation="definitionSelected ? '6' : '1'"
                :outlined="definitionSelected"
                :width="entityCardWidth"
                min-width="150px"
                @click="definitionSelectedHandler(true)"
            >
              <v-card-title class="pa-0 pb-2">
                <v-icon class="mr-1">
                  mdi-atom
                </v-icon>
                {{ getSelectedDefinitionText }}
                <v-spacer></v-spacer>
                <v-icon v-if="definitionMapped" class="mr-n2 mt-n6" color="green">
                  mdi-checkbox-marked-circle
                </v-icon>
              </v-card-title>
              <v-card-subtitle class="pb-0 pr-0 font-weight-light">
                {{getSelectedDefinitionSubText}}
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
              clearable
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
              clearable
          ></v-autocomplete>

          <v-text-field
              v-model="name"
              class="pt-0"
              label="Name"
              :disabled="!entitySelected"
              clearable
          ></v-text-field>

          <v-container class="pa-0">
            <v-row justify="center" align="center">
              <v-col cols="auto" class="pa-1 pb-2">
                <v-btn
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
        <v-expansion-panel-content class="mx-n3">
          <mapped-elements/>
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
import MappingSource from "@/components/MapperSource.vue";

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
    MapperSource: () => import('@/components/MapperSource.vue'),
    GlobalToast: () => import('@/components/GlobalToast'),
    MappedElements: () => import('@/components/MappedElements.vue')
  },
  data() {
    return {
      sourceUpToDate: true,
      // Expanded indexes for selection table (Types)
      selectionExpandedIndexes: [],
      // Expanded indexes for mapped element table (Categories)
      mappedElementsExpandedIndexes: [],
      // Whether definition card is selected to map or not.
      definitionSelected: false,
      // Initial entity (Group, Component, Face, Edge) that mapped or not
      entityMapped: false,
      // Definition of entity is mapped, it will be available for only Components.
      definitionMapped: false,
      // Whether an entity is selected or not.
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
      panel: [2],
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
    lastSelectedEntityHasParent(){
      return this.lastSelectedEntity['entityType'] === 'Component'
    },
    selectedEntitiesHasParent(){
      return this.selectedEntities.every((entity) => entity['entityType'] === 'Component')
    },
    entityCardWidth(){
      if (this.lastSelectedEntityHasParent){
        return '150px'
      } else {
        return '310px'
      }
    },
    entityCardElevation(){
      if (!this.lastSelectedEntityHasParent){
        return '1'
      }
      return this.definitionSelected ? '1' : '6'
    },
    entityCardColor(){
      if (!this.lastSelectedEntityHasParent){
        return 'background2'
      }
      return this.definitionSelected ? 'background2' : 'mappingEntity'
    },
    getSelectedEntityIcon(){
      if (this.selectedEntities.length > 1){
        return 'mdi-webpack'
      }else{
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
    getSelectedEntityText(){
      if (this.selectedEntities.length > 1){
        if (this.selectedEntitiesHasParent){
          return 'Component'
        }
        return 'Multiple Selection'
      }else{
        return this.lastSelectedEntity["entityType"]
      }
    },
    getSelectedDefinitionText(){
      if (this.selectedEntities.length > 1 && this.selectedEntitiesHasParent){
        return 'Definition'
      }else{
        return 'Definition'
      }
    },
    getSelectedEntitySubText(){
      if (this.selectedEntities.length > 1){
        return this.getSelectionSummary()
      }else{
        return 'Single selected entity'
      }
    },
    getSelectedDefinitionSubText(){
        if (this.selectedEntities.length > 1){
            let instances = 0
            let registeredDefinitions = []
            this.selectedEntities.forEach((entity) => {
                if (!registeredDefinitions.includes(entity['definition']['entityId'])){
                    instances += entity['definition']['numberOfInstances']
                    registeredDefinitions.push(entity['definition']['entityId'])
                }
            })
            return `Instances (${instances})`
        }else{
            return `Instances (${this.lastSelectedEntity['definition']['numberOfInstances']})`
        }
    }
  },
  methods:{
    refreshSourceBranch(){
      bus.$emit('refresh-source-branch')
    },
    clearInputs(){
      this.enabledMethods = []
      this.availableCategories = []
      this.selectedEntities = []
      this.selectionTableData = []
      this.selectedEntityCount = 0
      this.name = ""
      this.selectedMethod = null
      this.selectedCategory = null
      this.entityMapped = false
      this.definitionMapped = false
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
                  'isMapped': this.isEntityMapped(entity) || this.isEntityDefinitionMapped(entity)
                }
              }),
              'mappedCount': entities.filter((entity) => entity['schema']['category'] !== undefined).length
            }
          }
      )
    },
    getSelectionSummary(){
      let groupByClass = groupBy('entityType')
      let groupedByWithKey = groupByClass(this.selectedEntities)
      let summary = ''
      Object.entries(groupedByWithKey).forEach((entry, index) => {
        const [className, entities] = entry
          const entityType = className === 'Component' ? 'Instance' : className
        summary += `${entityType}s (${entities.length})`
        if (index !== Object.entries(groupedByWithKey).length - 1){
          summary += ' - '
        }
      })
      return summary
    },
    setInputValuesFromSelection(){
      if (!this.entitySelected){
        this.name = ""
        this.selectedMethod = null
        this.selectedCategory = null
        return
      }
      if (this.definitionSelected) {
        if (!this.definitionMapped){
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['definition']['entityName']
          }
          this.selectedMethod = 'Direct Shape'
          this.selectedCategory = 49
        } else {
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['definition']['schema']['name']
          }
          this.selectedMethod = this.lastSelectedEntity['definition']['schema']['method']
          this.selectedCategory = this.lastSelectedEntity['definition']['schema']['category']
        }
      } else {
        if (!this.entityMapped){
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['entityName']
          }
          this.selectedMethod = 'Direct Shape'
          this.selectedCategory = 49
        } else {
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['schema']['name']
          }
          this.selectedMethod = this.lastSelectedEntity['schema']['method']
          this.selectedCategory = this.lastSelectedEntity['schema']['category']
        }
      }
    },
    isEntityMapped(entity){
      return entity['schema']['category'] !== undefined
    },
    isEntitiesMapped(entities){
      return entities.every((entity) => this.isEntityMapped(entity))
    },
    isEntityDefinitionMapped(entity){
      if (entity['definition'] === undefined){
        return false
      }
      return entity['definition']['schema']['category'] !== undefined
    },
    isEntityDefinitionsMapped(entities){
      return entities.every((entity) => this.isEntityDefinitionMapped(entity))
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
    sketchup.exec({name: "collect_mapped_entities", data: {}})

    bus.$on('entities-selected', async (selectionParameters) => {
      const selectionPars = JSON.parse(selectionParameters)
      this.enabledMethods = selectionPars.mappingMethods
      this.availableCategories = selectionPars.categories
      this.selectedEntities = selectionPars.selection
      this.lastSelectedEntity = this.selectedEntities[this.selectedEntities.length - 1]
      this.entityMapped = this.isEntitiesMapped(this.selectedEntities)
      this.definitionMapped = this.isEntityDefinitionsMapped(this.selectedEntities)
      this.definitionSelected = !this.entityMapped && this.definitionMapped
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
    })
    bus.$on('set-source-up-to-date', (isUpToDate) => {
      this.sourceUpToDate = isUpToDate
      console.log(this.sourceUpToDate)
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

.v-card__title{
    font-size: 1.02rem;
}

.v-card__subtitle{
    font-size: 0.78rem;
}

.v-expansion-panel--active > .v-expansion-panel-header{
    min-height: 32px;
}

.v-expansion-panel-header{
    min-height: 32px;
    padding: 12px 16px;
}

</style>