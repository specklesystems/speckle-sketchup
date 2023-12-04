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
            <v-tooltip right>
              <template #activator="{ on, attrs }">
                <v-btn
                    class="ma-0 ml-1"
                    height="20px"
                    width="20px"
                    icon
                    x-small
                    :color="getSourceStateIconColor()"
                    v-bind="attrs"
                    v-on="on"
                    @click="refreshSourceBranch"
                >
                  <v-icon>
                    {{ getSourceStateIcon() }}
                  </v-icon>
                </v-btn>
              </template>
              <span>{{ getSourceStateToolTip() }}</span>
            </v-tooltip>

          </v-container>
        </v-expansion-panel-header>
        <v-expansion-panel-content>
          <mapper-source :stream-text="streamText" :branch-text="branchText" :source-state="this.sourceState"/>
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
              :items="availableMethods"
              density="compact"
              clearable
              @change="onSelectedMethodChange"
          ></v-autocomplete>

          <v-autocomplete
              v-if="familySelectionActive"
              v-model="selectedFamily"
              class="pt-0"
              label="Family"
              :disabled="!entitySelected"
              :items="families"
              density="compact"
              clearable
              @change="onSelectedFamilyChange"
          ></v-autocomplete>

          <v-autocomplete
              v-if="typeSelectionActive"
              v-model="selectedFamilyType"
              class="pt-0"
              label="Type"
              :disabled="!entitySelected"
              item-value="type"
              item-text="type"
              :items="familyTypes"
              density="compact"
              clearable
          ></v-autocomplete>

          <v-autocomplete
              v-if="levelSelectionActive"
              v-model="selectedLevel"
              class="pt-0"
              label="Base Level"
              :disabled="!entitySelected"
              :items="levels"
              item-value="name"
              item-text="name"
              density="compact"
              clearable
          ></v-autocomplete>

          <v-autocomplete
              v-if="categorySelectionActive"
              v-model="selectedCategory"
              class="pt-0"
              label="Category"
              :items="selectedMethod === 'New Revit Family' ? familyCategories : categories"
              item-value="value"
              item-text="key"
              :disabled="!entitySelected"
              density="compact"
              clearable
          ></v-autocomplete>

          <v-text-field
              v-if="nameSelectionActive"
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
                    small
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
                    small
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
import {sourceMap} from "@vue/cli-service/lib/config/terserOptions";

global.mapperSourceUpdated = function (streamId, levels, types) {
  console.log(`Mapper source updated for ${streamId}.`)
}

global.entitySelected = function (selectionParameters) {
  bus.$emit('entities-selected', JSON.stringify(selectionParameters))
}

global.mapperInitialized = function (initParameters) {
  bus.$emit('mapper-initialized', JSON.stringify(initParameters))
}

global.entitiesDeselected = function () {
  bus.$emit('entities-deselected')
}

global.mappedEntitiesUpdated = function (mappedEntities) {
  bus.$emit('mapped-entities-updated', mappedEntities)
}

export default {
  name: "Mapper",
  props: {
    streamText: {
      type: String,
      default: ''
    },
    branchText: {
      type: String,
      default: ''
    }
  },
  components: {
    MapperSource: () => import('@/components/MapperSource.vue'),
    GlobalToast: () => import('@/components/GlobalToast'),
    MappedElements: () => import('@/components/MappedElements.vue')
  },
  data() {
    return {
      nativeFaceMethods: ['Floor', 'Wall'],
      nativeEdgeMethods: ['Column', 'Beam', 'Brace', 'Pipe', 'Duct'],
      nativeDefaultFaceMethods: ['Default Floor', 'Default Wall'],
      nativeDefaultEdgeMethods: ['Default Column', 'Default Beam', 'Default Brace', 'Default Pipe', 'Default Duct'],

      familySelectionActive: false,
      typeSelectionActive: false,
      levelSelectionActive: false,
      categorySelectionActive: false,
      nameSelectionActive: false,

      sourceState: 'Not Set',
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
      allFamilyTypes: {},
      familyTypes: [],
      lastSelectedEntity: null,

      selectedMethod: null,
      selectedCategory: null,
      selectedFamily: null,
      selectedFamilyType: null,
      selectedLevel: null,
      name: "",

      availableMethods: [],
      categories: [],
      familyCategories: [],

      families: [],
      allTypes: {},
      levels: [],

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
    getSourceStateIcon(){
      switch (this.sourceState){
        case "Not Set":
          return `mdi-cloud-off-outline`;
        case "Set":
          return `mdi-checkbox-marked-circle-outline`;
        case "Outdated":
          return `mdi-update`;
        default:
          break;
      }
    },
    getSourceStateToolTip(){
      switch (this.sourceState){
        case "Not Set":
          return 'Source disconnected.';
        case "Set":
          return 'Source connected.';
        case "Outdated":
          return 'Source branch is not up-to-date!';
        default:
          break;
      }
    },
    getSourceStateIconColor(){
      switch (this.sourceState){
        case "Not Set":
          return `grey`;
        case "Set":
          return `green`;
        case "Outdated":
          return `red`;
        default:
          break;
      }
    },
    onSelectedMethodChange(){
      this.hideOptionalMappingInputs()
      this.updateMappingInputs()
      this.getFamiliesFromSelectedMethod()
      this.getTypesFromSelectedFamily()
      this.$mixpanel.track('MappingsAction', { name: 'Mappings Set', schema: this.selectedMethod })
    },
    onSelectedFamilyChange(){
      this.getTypesFromSelectedFamily();
    },
    updateMappingInputs(){
      if (this.selectedMethod === null){
        this.typeSelectionActive = false
        this.familySelectionActive = false
        this.levelSelectionActive = false
        this.categorySelectionActive = false
        this.nameSelectionActive = false
        return
      }
      const nativeDefaultMethods = this.nativeDefaultEdgeMethods.concat(this.nativeDefaultFaceMethods)
      const nativeMethods = this.nativeEdgeMethods.concat(this.nativeFaceMethods)

      if (this.selectedMethod === 'Direct Shape'){
        this.categorySelectionActive = true
        this.nameSelectionActive = true
      }
      else if (this.selectedMethod === 'New Revit Family'){
        this.categorySelectionActive = true
      }
      else if (nativeDefaultMethods.includes(this.selectedMethod)){
        this.typeSelectionActive = false
        this.familySelectionActive = false
        this.levelSelectionActive = false
        this.categorySelectionActive = false
        this.nameSelectionActive = false
      }
      else if (nativeMethods.includes(this.selectedMethod)){
        this.typeSelectionActive = true
        this.familySelectionActive = true
        this.levelSelectionActive = true
      }
    },
    getTypesFromSelectedFamily(){
      if (this.sourceState !== 'Not Set'){
        this.familyTypes = this.allFamilyTypes[this.selectedFamily]
        this.selectedFamilyType = this.familyTypes[0].type
        if (this.selectedFamilyType === null || this.selectedFamilyType === undefined){
          this.selectedFamilyType = this.familyTypes[0].type
        }
      }
      if (this.selectedFamily === null || this.selectedFamily === undefined){
        this.selectedFamily = this.families[0]
      }
      if (this.familyTypes === null ||this.familyTypes === undefined){
        this.familyTypes = this.allFamilyTypes[this.selectedFamily]
      }

    },
    getFamiliesFromSelectedMethod(){
      switch (this.selectedMethod) {
        case 'Floor':
          this.families = Object.keys(this.allTypes['Floors']);
          this.allFamilyTypes = this.allTypes['Floors']
          break;
        case 'Wall':
          this.families = Object.keys(this.allTypes['Walls']);
          this.allFamilyTypes = this.allTypes['Walls']
          break;
        case 'Column':
          this.families = Object.keys(this.allTypes['Columns']);
          this.allFamilyTypes = this.allTypes['Columns']
          break;
        case 'Beam':
          this.families = Object.keys(this.allTypes['Beams']);
          this.allFamilyTypes = this.allTypes['Beams']
          break;
        case 'Pipe':
          this.families = Object.keys(this.allTypes['Piping System']);
          this.allFamilyTypes = this.allTypes['Piping System']
          break;
        case 'Duct':
          this.families = Object.keys(this.allTypes['Duct System']);
          this.allFamilyTypes = this.allTypes['Duct System']
          break;
        default:
          break;
      }
      if (this.selectedFamily === null || this.selectedFamily === undefined){
        this.selectedFamily = this.families[0]
      }
      if (this.sourceState === 'Set'){
        if (this.selectedLevel === null || this.selectedLevel === undefined){
          this.selectedLevel = this.levels[0].name
        }
      }
    },
    hideOptionalMappingInputs(){
      this.categorySelectionActive = false
      this.nameSelectionActive = false
      this.typeSelectionActive = false
      this.familySelectionActive = false
      this.levelSelectionActive = false
    },
    refreshSourceBranch(){
      if (this.sourceState === 'Outdated'){
        bus.$emit('refresh-source-branch')
        this.$mixpanel.track('MappingsAction', { name: 'Mappings Source Update' })
      }
    },
    clearInputs(){
      this.availableMethods = []
      this.selectedEntities = []
      this.selectionTableData = []
      this.selectedEntityCount = 0
      this.name = ""
      this.selectedMethod = null
      this.selectedCategory = null
      this.entityMapped = false
      this.definitionMapped = false
      this.selectedLevel = null
      this.selectedFamily = null
      this.selectedFamilyType = null
      this.allTypes = null
      this.familyTypes = null
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
      // Clear all inputs if entity is not selected.
      if (!this.entitySelected){
        this.clearMappingInputs()
        return
      }
      // Check if definition card is selected and set definition mappings.
      if (this.definitionSelected) {
        if (!this.definitionMapped){
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['definition']['entityName']
          }
          // this.selectedMethod = 'Direct Shape'
          this.selectedCategory = 49
        } else {
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['definition']['schema']['name']
          }
          this.selectedMethod = this.lastSelectedEntity['definition']['schema']['method']
          this.selectedCategory = this.lastSelectedEntity['definition']['schema']['category']
          this.updateMappingInputs()
        }
      }
      // Otherwise set entity mappings.
      else
      {
        if (!this.entityMapped){
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['entityName']
          }
          this.updateMappingInputs()
          this.getFamiliesFromSelectedMethod()
          this.getTypesFromSelectedFamily()
          this.selectedCategory = 49
        } else {
          if (this.selectedEntityCount > 1){
            this.name = '<Mixed>'
          }else{
            this.name = this.lastSelectedEntity['schema']['name']
          }
          this.selectedMethod = this.lastSelectedEntity['schema']['method']
          this.updateMappingInputs()
          this.selectedFamily = this.lastSelectedEntity['schema']['family']
          this.selectedCategory = this.lastSelectedEntity['schema']['category']
          this.getFamiliesFromSelectedMethod()
          this.getTypesFromSelectedFamily()
          this.selectedFamilyType = this.lastSelectedEntity['schema']['family_type']
          this.selectedLevel = this.lastSelectedEntity['schema']['level']
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
    inputsReadyToApply(){
      if (this.selectedMethod === null || this.selectedMethod === undefined){
        return false;
      }

      const nativeMethods = this.nativeEdgeMethods.concat(this.nativeFaceMethods)

      if (this.selectedMethod === 'Direct Shape'){
        return this.selectedCategory !== null
      }
      else if (nativeMethods.includes(this.selectedMethod)){
        return this.selectedFamily !== null &&
            this.selectedFamilyType !== null &&
            this.selectedLevel !== null
      }
      else {
        return true;
      }
    },
    applyMapping(){
      if (!this.inputsReadyToApply()){
        this.$eventHub.$emit('error', {
          text: 'Some inputs are not set to apply mapping.\n'
        })
        return
      }
      const mapping = {
        entitiesToMap: this.selectedEntities.map((entity) => entity['entityId']),
        method: this.selectedMethod,
        category:  this.selectedCategory,
        family: this.selectedFamily,
        familyType: this.selectedFamilyType,
        level: this.selectedLevel,
        name: this.name,
        isDefinition: this.definitionSelected
      }
      sketchup.exec({name: "apply_mappings", data: mapping})
      this.$eventHub.$emit('success', {
        text: 'Mapping Applied.\n'
      })

      this.$mixpanel.track('MappingsAction', { name: 'Mappings Applied' })
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
      this.$mixpanel.track('MappingsAction', { name: 'Mappings Clear' })
    },
    clearMappingInputs(){
      this.selectedMethod = null
      this.selectedCategory = null
      this.name = ""
      this.selectedFamily = null
      this.selectedFamilyType = null
      this.selectedLevel = null
      this.familyTypes = null
      this.levels = null
      this.availableMethods = null
      this.allTypes = null
    },
    getDataFromSelection(selectionParameters){
      this.availableMethods = selectionParameters.mappingMethods
      this.selectedEntities = selectionParameters.selection
      this.allTypes = selectionParameters.types
      this.levels = selectionParameters.levels
      this.selectedLevel = selectionParameters.selectedLevelName
    },
    updateStatesFromSelectionData(){
      this.lastSelectedEntity = this.selectedEntities[this.selectedEntities.length - 1]
      this.entityMapped = this.isEntitiesMapped(this.selectedEntities)
      this.definitionMapped = this.isEntityDefinitionsMapped(this.selectedEntities)
      this.definitionSelected = !this.entityMapped && this.definitionMapped
      this.selectedEntityCount = this.selectedEntities.length
      this.entitySelected = this.selectedEntityCount !== 0
    }
  },
  mounted() {
    sketchup.exec({name: "mapper_initialized", data: {}})
    sketchup.exec({name: "collect_mapped_entities", data: {}})

    bus.$on('mapper-initialized', async (initParameters) => {
      const initPars = JSON.parse(initParameters)
      this.categories = initPars.categories
      this.familyCategories = initPars.familyCategories
    })

    bus.$on('entities-selected', async (selectionParameters) => {
      // Parse data to json object
      const selectionPars = JSON.parse(selectionParameters)
      // Reset mapping inputs with nulls and empties.
      this.clearMappingInputs()
      // Get data from selection into objects and arrays. These data basically constructs the dropdowns.
      this.getDataFromSelection(selectionPars)
      // Update inner state of the mapper component according to selection data.
      this.updateStatesFromSelectionData()
      // Get selection table data.
      this.getSelectionTableData()
      // Set mapping input values from selection data.
      this.setInputValuesFromSelection()
    })
    bus.$on('entities-deselected', async () => {
      this.entitySelected = false
      this.clearInputs()
      this.hideOptionalMappingInputs()
    })
    bus.$on('mapped-entities-updated', async (mappedEntities) => {
      this.mappedEntityCount = mappedEntities.length
    })
    bus.$on('set-source-up-to-date', (isUpToDate) => {
      this.sourceState = isUpToDate
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