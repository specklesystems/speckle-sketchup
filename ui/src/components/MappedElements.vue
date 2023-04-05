<template>
  <v-container class="pa-0">
    <v-data-table
        :v-model="categorySelection()"
        class="elevation-1 mb-5"
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
        show-select
    >
      <template v-slot:expanded-item="{ headers, item }">
        <td :colspan="headers.length" class="pl-2 pr-0 lighten-3 grey">
          <v-data-table
              v-model="elementSelection[item.categoryName]['selectedElements']"
              class="elevation-0 pa-0 ma-0"
              dense
              disable-filtering
              disable-pagination
              hide-default-footer
              hide-default-header
              item-key="entityId"
              :headers="subMappedElementsHeaders"
              :items="item.entities"
              :mobile-breakpoint="0"
              show-select
          >
            <template #[`item.data-table-select`]="slotData">
                <td class="mapped-elements-check-box-row">
                    <v-checkbox
                            class="shrink ma-0"
                            hide-details
                            :value="slotData.isSelected"
                            @click="slotData.select(clickMappedElements(slotData, item.categoryName))"
                    />
                </td>
            </template>
          </v-data-table>
        </td>
      </template>

      <template #[`header.name`]="{ header }">
          <th class="header-text-color">{{ header.text.toUpperCase() }}</th>
      </template>

      <template #[`item.categoryName`]="slotData">
        <div @click="clickMappedElementsCategory(slotData)">{{ slotData.item.categoryName }}</div>
      </template>

      <template #[`item.data-table-select`]="slotData">
        <v-checkbox
                class="shrink ma-0"
                hide-details
                :value="slotData.isSelected"
                @click="slotData.select(clickMappedCategory(slotData))"
        />
      </template>

    </v-data-table>
      <v-container class="btn-container">
        <v-btn
          v-tooltip="'Clear Mappings'"
          x-small
          min-width="30px"
          min-height="30px"
          @click="clearMappingsFromTableSelection"
        >
          <v-icon small dark>
              mdi-delete
          </v-icon>
        </v-btn>

        <v-spacer></v-spacer>

        <v-btn
          v-tooltip="'Isolate Mapped Elements'"
          x-small
          min-width="30px"
          min-height="30px"
          class="mr-2"
          @click="isolateMappedElementsOnSketchup"
        >
          <v-icon small dark>
            mdi-cube-outline
          </v-icon>
        </v-btn>

        <v-btn
          v-tooltip="'Show Mapped Elements'"
          x-small
          min-width="30px"
          min-height="30px"
          class="mr-2"
          @click="showMappedElementsOnSketchup"
        >
          <v-icon small dark>
            mdi-eye
          </v-icon>
        </v-btn>

        <v-btn
          v-tooltip="'Select Mapped Elements'"
          x-small
          min-width="30px"
          min-height="30px"
          @click="selectMappedElementsOnSketchup"
        >
          <v-icon small dark>
            mdi-cursor-default
          </v-icon>
        </v-btn>
      </v-container>
  </v-container>
</template>

<script>
/*global sketchup*/
import {bus} from "@/main";
import {groupBy} from "@/utils/groupBy";

export default {
  name: "MappedElements",
  data(){
    return {
      elementSelection: {},
      mappedEntities: [],
      mappedEntityCount: 0,
      // Expanded indexes for mapped element table (Categories)
      mappedElementsExpandedIndexes: [],
      mappedElementsHeaders: [
        { text: 'Category', sortable: false, value: 'categoryName', width: '70%' },
        { text: 'Count', sortable: false, align: 'center', value: 'count', width: '30%' }
      ],
      subMappedElementsHeaders: [
        { text: 'Type', sortable: false, value: 'entityType', width: '70%' },
        { text: 'Name/Id', sortable: false, align: 'center', value: 'nameOrId', width: '30%' },
      ],
      mappedEntitiesTableData: [],
    }
  },
  computed: {
    // categorySelection() {
    //     return Object.keys(this.elementSelection)
    // },
  },
  mounted() {
    sketchup.exec({name: "collect_mapped_entities", data: {}})

    bus.$on('mapped-entities-updated', async (mappedEntities) => {
      this.mappedEntityCount = mappedEntities.length
      this.mappedEntities = mappedEntities
      this.getMappedElementsTableData()
    })
  },
  methods: {
    categorySelection() {
        return Object.keys(this.elementSelection)
    },
    clickMappedElementsCategory(slotData) {
      const indexExpanded = this.mappedElementsExpandedIndexes.findIndex(i => i === slotData.item);
      if (indexExpanded > -1) {
        this.mappedElementsExpandedIndexes.splice(indexExpanded, 1)
      } else {
        this.mappedElementsExpandedIndexes.push(slotData.item);
      }
    },
    clickMappedCategory(slotData){
        const category = this.elementSelection[slotData.item.categoryName]
        if (category['allSelected'] || category['selectedElements'].length === category['entityCount']) {
            this.elementSelection[slotData.item.categoryName]['allSelected'] = false
            this.elementSelection[slotData.item.categoryName]['selectedElements'] = []
        } else {
            this.elementSelection[slotData.item.categoryName]['allSelected'] = true
            this.elementSelection[slotData.item.categoryName]['selectedElements'] = slotData.item.entities
        }
        console.log(this.elementSelection)
    },
    clickMappedElements(slotData, category){
        const elements = this.elementSelection[category]['selectedElements'] === undefined ? [] : this.elementSelection[category]['selectedElements']
        const indexSelection = elements.findIndex(i => i === slotData.item);
        if (indexSelection > -1) {
            elements.splice(indexSelection, 1)
        } else {
            elements.push(slotData.item);
        }
        this.elementSelection[category]['selectedElements'] = elements
        console.log(this.elementSelection)
    },
    clearMappingsFromTableSelection(){

    },
    isolateMappedElementsOnSketchup(){

    },
    showMappedElementsOnSketchup(){

    },
    selectMappedElementsOnSketchup(){

    },
    getMappedElementsTableData(){
      let groupByCategoryName = groupBy('categoryName')
      let groupedByCategoryName = groupByCategoryName(this.mappedEntities)
      this.mappedEntitiesTableData = Object.entries(groupedByCategoryName).map(
        (entry) => {
          const [categoryName, entities] = entry
            this.elementSelection[categoryName] = { allSelected: false, entityCount: entities.length, selectedElements: [] }
          return {
            'categoryName': categoryName,
            'count': entities !== true ? entities.length : 0,
            'entities': entities.map((entity) => {
              return {
                'entityId': entity['entityId'],
                'nameOrId': entity['name'] !== "" ? entity['name'] : entity['entityId'],
                'entityType': entity['entityType']
              }
            })
          }
        }
      )
    },
  }
}
</script>

<style scoped>
.btn-container{
  display: flex;
  flex-wrap: wrap;
}

.v-application--is-ltr .v-input--selection-controls__input{
  margin-right: 0;
}

.header-text-color{
    color: red;
}

.mapped-elements-check-box-row {
    width: 20px;
}

</style>