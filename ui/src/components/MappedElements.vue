<template>
  <v-container class="pa-0">
    <v-data-table
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
        <td :colspan="headers.length" class="pl-2 pr-0">
          <v-data-table
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

    <v-btn>
      test
    </v-btn>
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
      mappedEntities: [],
      mappedEntityCount: 0,
      // Expanded indexes for mapped element table (Categories)
      mappedElementsExpandedIndexes: [],
      mappedElementsHeaders: [
        { text: 'Category', sortable: false, value: 'categoryName', width: '80%' },
        { text: 'Count', sortable: false, align: 'center', value: 'count', width: '20%' }
      ],
      subMappedElementsHeaders: [
        { text: 'Type', sortable: false, value: 'entityType', width: '80%' },
        { text: 'Name/Id', sortable: false, align: 'center', value: 'nameOrId', width: '20%' },
      ],
      mappedEntitiesTableData: [],
    }
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
    clickMappedElementsColumn(slotData) {
      const indexExpanded = this.mappedElementsExpandedIndexes.findIndex(i => i === slotData.item);
      if (indexExpanded > -1) {
        this.mappedElementsExpandedIndexes.splice(indexExpanded, 1)
      } else {
        this.mappedElementsExpandedIndexes.push(slotData.item);
      }
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

.v-input--selection-controls__input{
  margin-right: 0px;
}
</style>