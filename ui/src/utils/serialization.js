const zlib = require('zlib')
const crypto = require('crypto')

export class BaseObjectSerializer {
  constructor(defaultChunkSize = 1000) {
    this.defaultChunkSize = defaultChunkSize
    this._resetWriter()
  }

  _resetWriter() {
    this.detachLineage = []
    this.lineage = []
    this.familyTree = {}
    this.closureTable = {}
    this.objects = {}
  }

  writeJson(base) {
    this._resetWriter()
    self.detachLineage = [true]
    let { hash, traversed } = this.traverseBase(base)
    this.objects[hash] = traversed
    let serialized = JSON.stringify(traversed)
    return { hash, serialized }
  }

  traverseBase(base) {
    this.lineage.push(crypto.randomBytes(16).toString('hex'))

    let traversed = { id: '', speckle_type: base.speckle_type, totalChildrenCount: 0 }
    for (let prop in base) {
      const val = base[prop]
      // ignore nulls and don't pre-populate the id
      if (val === null || prop.startsWith('_') || prop == 'id') continue
      // don't need to process primitives
      if (typeof val !== 'object') {
        traversed[prop] = val
        continue
      }

      const detach = prop.startsWith('@')

      // 1. chunked arrays
      let detachMatch = prop.match(/^@\((\d*)\)/) // chunk syntax
      if (Array.isArray(val) && detachMatch) {
        const chunkSize = detachMatch[1] !== '' ? parseInt(detachMatch[1]) : this.defaultChunkSize
        let chunks = []
        let chunk = {
          // eslint-disable-next-line camelcase
          speckle_type: 'Speckle.Core.Models.DataChunk',
          data: []
        }
        val.forEach((el, count) => {
          if (count && count % chunkSize == 0) {
            chunks.push(chunk)
            chunk = {
              // eslint-disable-next-line camelcase
              speckle_type: 'Speckle.Core.Models.DataChunk',
              data: []
            }
          }

          chunk.data.push(el)
        })
        if (chunk.data.length !== 0) chunks.push(chunk)

        let chunkRefs = []
        chunks.forEach((chunk) => {
          this.detachLineage.push(detach) // true
          let { hash } = this.traverseBase(chunk)
          chunkRefs.push(this.detachHelper(hash))
        })

        traversed[prop.replace(detachMatch[0], '')] = chunkRefs // strip chunk syntax
        continue
      }

      // strip leading '@' for detach (to be removed in the future when we have a way
      // to keep track of detachable props to be consistent with sharp and py)
      if (detach) prop = prop.substring(1)
      // 2. base object
      if (val.speckle_type) {
        let child = this.traverseValue({ value: val, detach: detach })
        traversed[prop] = detach ? this.detachHelper(child.id) : child
      } else {
        // 3. anything else (dicts, lists)
        traversed[prop] = this.traverseValue({ value: val, detach: detach })
      }
    }

    const detached = this.detachLineage.pop()

    // add closures and total children count
    let closure = {}
    const parent = this.lineage.pop()
    if (this.familyTree[parent]) {
      Object.entries(this.familyTree[parent]).forEach(([ref, depth]) => {
        closure[ref] = depth - this.detachLineage.length
      })
    }

    traversed['totalChildrenCount'] = Object.keys(closure).length

    const hash = this.getId(traversed)

    traversed.id = hash
    if (traversed['totalChildrenCount']) {
      traversed['__closure'] = this.closureTable[hash] = closure
    }

    // save obj string if detached
    if (detached) this.objects[hash] = traversed

    return { hash, traversed }
  }

  traverseValue({ value, detach = false }) {
    // 1. primitives
    if (typeof value !== 'object') return value

    // 2. arrays
    if (Array.isArray(value)) {
      if (!detach) return value.map((el) => this.traverseValue({ value: el }))

      let detachedList = []
      value.forEach((el) => {
        if (typeof el === 'object' && el.speckle_type) {
          this.detachLineage.push(detach)
          let { hash } = this.traverseBase(el)
          detachedList.push(this.detachHelper(hash))
        } else {
          detachedList.push(this.traverseValue({ value: el, detach: detach }))
        }
      })
      return detachedList
    }

    // 3. dicts
    if (!value.speckle_type) return value

    // 4. base objects
    if (value.speckle_type) {
      this.detachLineage.push(detach)
      return this.traverseBase(value).traversed
    }

    throw `Unsupported type '${typeof value}': ${value}`
  }

  detachHelper(refHash) {
    this.lineage.forEach((parent) => {
      if (!this.familyTree[parent]) this.familyTree[parent] = {}
      if (
        !this.familyTree[parent][refHash] ||
        this.familyTree[parent][refHash] > this.detachLineage.length
      ) {
        this.familyTree[parent][refHash] = this.detachLineage.length
      }
    })
    return {
      referencedId: refHash,
      // eslint-disable-next-line camelcase
      speckle_type: 'reference'
    }
  }

  getId(obj) {
    return crypto.createHash('md5').update(JSON.stringify(obj)).digest('hex')
  }

  batchObjects(maxBatchSizeMb = 1) {
    const maxSize = maxBatchSizeMb * 1000 * 1000
    let batches = []
    let batch = []
    let batchSize = 0
    console.log('START batching objects')
    let objects = Object.values(this.objects)
    objects.forEach((obj) => {
      let currObj = JSON.stringify(obj)
      if (batchSize + currObj.length < maxSize) {
        batch.push(obj)
        batchSize += currObj.length
      } else {
        batches.push(batch)
        batch = [currObj]
        batchSize = currObj.length
      }
    })
    batches.push(batch)

    console.log('batches:', batches)

    return batches
  }
}
