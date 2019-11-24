//
//  File.swift
//  
//
//  Created by Pawel Rup on 24/11/2019.
//

import Foundation

/// Provides indirection for a given instance.
/// For value types, value semantics are preserved.
struct Indirect<T> {

  // Class wrapper to provide the actual indirection.
  private final class Wrapper {

    var value: T

    init(_ value: T) {
      self.value = value
    }
  }

  private var wrapper: Wrapper

  init(_ value: T) {
    wrapper = Wrapper(value)
  }

  var value: T {
    get {
      return wrapper.value
    }
    set {
      // Upon mutation of value, if the wrapper class instance is unique,
      // mutate the underlying value directly.
      // Otherwise, create a new instance.
      if isKnownUniquelyReferenced(&wrapper) {
        wrapper.value = newValue
      } else {
        wrapper = Wrapper(newValue)
      }
    }
  }
}
