<template>
  <v-container class="pa-0">
    <v-data-table
        v-model="categorySelection"
        class="elevation-1 mb-2"
        dense
        expand
        disable-filtering
        disable-pagination
        hide-default-footer
        hide-default-header
        item-key="categoryName"
        :expanded.sync="mappedElementsExpandedIndexes"
        :headers="mappedElementsHeaders"
        :items="mappedEntitiesTableData"
        :mobile-breakpoint="0"
        show-select
    >
        <template #header="{ props: { headers } }">
            <thead class="v-data-table-header">
            <tr>
                <th
                        v-for="header in headers"
                        :key="header.value"
                        :width="header.width"
                        scope="col"
                        class="text-center"
                >
                    {{ header.text }}
                </th>
            </tr>
            </thead>
        </template>
      <template v-slot:expanded-item="{ headers, item }">
        <td :colspan="headers.length" class="pl-2 pr-0">
          <v-data-table
              v-model="elementSelection[item.categoryName]['selectedElements']"
              class="elevation-0 pa-0 ma-0 mb-2"
              dense
              disable-filtering
              disable-pagination
              hide-default-footer
              hide-default-header
              item-key="entityId"
              :headers="subMappedElementsHeaders"
              :items="elementSelection[item.categoryName]['allElements']"
              :mobile-breakpoint="0"
              show-select
          >
            <template #header="{ props: { headers } }">
              <thead class="v-data-table-header">
                <tr>
                  <th
                          v-for="header in headers"
                          :key="header.value"
                          :width="header.width"
                          scope="col"
                          class="text-center"
                  >
                      {{ header.text }}
                  </th>
                </tr>
              </thead>
            </template>
            <template #[`item.data-table-select`]="slotData">
              <td class="mapped-elements-check-box-row">
                <v-checkbox
                        class="shrink ma-0"
                        hide-details
                        :input-value="slotData.isSelected"
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
                :input-value="slotData.isSelected"
                @click="slotData.select(clickMappedCategory(slotData))"
        />
      </template>

    </v-data-table>
      <v-container class="btn-container px-0">
        <v-btn
          v-tooltip="'Clear Mappings'"
          x-small
          min-width="30px"
          min-height="30px"
          @click="clearMappingsFromTableSelection"
        >
          <v-icon left dark>
              mdi-delete
          </v-icon>
            Clear
        </v-btn>

        <v-spacer></v-spacer>

        <v-btn
          v-tooltip=" isIsolated ? 'Show All Elements' : 'Isolate Mapped Elements'"
          x-small
          min-width="30px"
          min-height="30px"
          class="mr-2"
          @click="isolateMappedElementsOnSketchup"
        >
          <v-icon left dark>
              {{ isIsolated ? 'mdi-crop-rotate' : 'mdi-crop'}}
          </v-icon>
          {{ isIsolated ? 'Show All' : 'Isolate'}}
        </v-btn>

        <v-btn
          v-tooltip="'Hide Mapped Elements'"
          x-small
          min-width="30px"
          min-height="30px"
          class="mr-2"
          @click="hideMappedElementsOnSketchup"
        >
          <v-icon left dark>
            mdi-eye-off
          </v-icon>
            Hide
        </v-btn>

        <v-btn
          v-tooltip="'Select Mapped Elements'"
          x-small
          min-width="30px"
          min-height="30px"
          @click="selectMappedElementsOnSketchup"
        >
          <v-icon left dark>
              mdi-select-all
          </v-icon>
            Select
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
      isIsolated: false,
      elementSelection: {},
      categorySelection: [],
      mappedEntities: [],
      mappedEntityCount: 0,
      // Expanded indexes for mapped element table (Categories)
      mappedElementsExpandedIndexes: [],
      mappedElementsHeaders: [
        { text: 'Category', sortable: false, align: 'center', value: 'categoryName', width: '70%' },
        { text: 'Count', sortable: false, align: 'center', value: 'count', width: '30%' }
      ],
      subMappedElementsHeaders: [
        { text: 'Type', sortable: false, align: 'center', value: 'entityType', width: '70%' },
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
    // categorySelection() {
    //     return Object.keys(this.elementSelection)
    // },
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
    },
    clickMappedElements(slotData, category){
        const elements = this.elementSelection[category]['selectedElements'] === undefined ? [] : this.elementSelection[category]['selectedElements']
        const indexSelection = elements.findIndex(i => i['entityId'] === slotData.item['entityId']);
        if (indexSelection > -1) {
            elements.splice(indexSelection, 1)
        } else {
            elements.push(slotData.item);
        }
        this.elementSelection[category]['selectedElements'] = elements
        // FIXME: This should be the ideal UX, but there is a problem with states currently.. Need to be fixed
        // if (elements.length === 0){
        //     this.elementSelection[category]['allSelected'] = false
        // }
    },
    clearMappingsFromTableSelection(){
      sketchup.exec({ name: "clear_mappings_from_table", data: this.elementSelection })
      this.$mixpanel.track('MappingsAction', { name: 'Mappings Clear' })
    },
    isolateMappedElementsOnSketchup(){
      if (this.isIsolated){
        this.isIsolated = false
        sketchup.exec({ name: "show_all_entities", data: {} })
        this.$mixpanel.track('MappingsAction', { name: 'Mappings Un-Isolate' })
      } else {
        this.isIsolated = true
        sketchup.exec({ name: "isolate_mappings_from_table", data: this.elementSelection })
        this.$mixpanel.track('MappingsAction', { name: 'Mappings Isolate' })
      }
    },
    hideMappedElementsOnSketchup(){
      sketchup.exec({ name: "hide_mappings_from_table", data: this.elementSelection })
      this.$mixpanel.track('MappingsAction', { name: 'Mappings Hide' })
    },
    selectMappedElementsOnSketchup(){
      sketchup.exec({ name: "select_mappings_from_table", data: this.elementSelection })
      this.$mixpanel.track('MappingsAction', { name: 'Mappings Select Elements' })
    },
    // Update mapped elements table whenever mapped elements has changed.
    getMappedElementsTableData(){
      let groupByCategoryName = groupBy('categoryName')
      let groupedByCategoryName = groupByCategoryName(this.mappedEntities)
      // Reset selected categories and elements whenever mapped elements states has changed
      this.elementSelection = {}
      this.categorySelection = []
      this.mappedElementsExpandedIndexes = []
      this.mappedEntitiesTableData = Object.entries(groupedByCategoryName).map(
        (entry) => {
          const [categoryName, entities] = entry
          this.elementSelection[categoryName] = {
              allSelected: false,
              entityCount: entities.length,
              selectedElements: [],
              allElements: entities.map((entity) => {
                  return {
                      'entityId': entity['entityId'],
                      'nameOrId': entity['name'] !== "" ? entity['name'] : entity['entityId'],
                      'entityType': entity['entityType']
                  }
              })
          }
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

.mapped-elements-check-box-row {
    width: 20px;
}

/* This is the header styles of child table */
.v-data-table--dense > .v-data-table__wrapper > table > thead > tr > th {
    height: 32px;
}

</style>