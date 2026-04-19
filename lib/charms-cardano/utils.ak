use aiken/collection/list
use aiken/primitive/bytearray

pub fn bytearray_to_list(ba: ByteArray) -> List<Int> {
  bytearray.foldr(
    ba,
    [],
    fn(b: Int, acc: List<Int>) -> List<Int> { list.push(acc, b) },
  )
}

// Interprets a ByteArray as a big-endian unsigned integer.
pub fn bytearray_to_int(ba: ByteArray) -> Int {
  bytearray.foldl(ba, 0, fn(b: Int, acc: Int) -> Int { acc * 256 + b })
}

test bal() {
  bytearray_to_list(#[10, 255, 30, 98]) == [10, 255, 30, 98]
}
