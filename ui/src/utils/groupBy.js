/*
 * Group by function definition to call it on demand.
 * @example
 *   const groupByBrand = groupBy('brand')
 *   const groupedByBrands1 = groupByBrand(array1)
 *   const groupedByBrands2 = groupByBrand(array2)
 */
export const groupBy = key => array =>
    array.reduce((objectsByKeyValue, obj) => {
        const value = obj[key];
        objectsByKeyValue[value] = (objectsByKeyValue[value] || []).concat(obj);
        return objectsByKeyValue;
    }, {});