(function (global) {
  'use strict';

  // Internal slots follow reachable owners and queued jobs through WeakMap
  // ephemerons. Closed objects retain their state while referenced, and an
  // unreachable owner/state cycle can be collected within the same document.
  const readableState = new WeakMap();
  const readerState = new WeakMap();
  const controllerState = new WeakMap();
  const byobRequestState = new WeakMap();
  const writableState = new WeakMap();
  const writerState = new WeakMap();
  const writableControllerState = new WeakMap();
  const transformState = new WeakMap();
  const transformControllerState = new WeakMap();
  const activePipeThroughOperations = new Set();

  // Geometrically grown ring: removing a head releases its reference without
  // moving the remaining entries. Backing arrays retain the runtime's limit.
  class StreamQueue {
    constructor() { this.items = []; this.head = 0; this.length = 0; }
    peek() { return this.length ? this.items[this.head] : undefined; }
    push(value) {
      if (this.length === this.items.length) {
        const items = new Array(this.items.length ? this.items.length * 2 : 8);
        for (let index = 0; index < this.length; index += 1) items[index] = this.items[(this.head + index) % this.items.length];
        this.items = items;
        this.head = 0;
      }
      this.items[(this.head + this.length) % this.items.length] = value;
      this.length += 1;
    }
    shift() {
      if (!this.length) return undefined;
      const value = this.items[this.head];
      this.items[this.head] = undefined;
      this.length -= 1;
      this.head = this.length ? (this.head + 1) % this.items.length : 0;
      return value;
    }
    clear() { this.items = []; this.head = 0; this.length = 0; }
  }

  const transferBuffer = ArrayBuffer.prototype.transfer;
  const typedPrototype = Object.getPrototypeOf(Uint8Array.prototype);
  const typedTag = Object.getOwnPropertyDescriptor(typedPrototype, Symbol.toStringTag).get;
  const viewConstructors = { Int8Array, Uint8Array, Uint8ClampedArray, Int16Array, Uint16Array, Int32Array, Uint32Array, Float16Array, Float32Array, Float64Array, BigInt64Array, BigUint64Array };
  const typedBuffer = Object.getOwnPropertyDescriptor(typedPrototype, 'buffer').get;
  const typedOffset = Object.getOwnPropertyDescriptor(typedPrototype, 'byteOffset').get;
  const typedLength = Object.getOwnPropertyDescriptor(typedPrototype, 'byteLength').get;
  const dataBuffer = Object.getOwnPropertyDescriptor(DataView.prototype, 'buffer').get;
  const dataOffset = Object.getOwnPropertyDescriptor(DataView.prototype, 'byteOffset').get;
  const dataLength = Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get;
  function describeView(view) {
    if (!ArrayBuffer.isView(view)) throw typeError('An ArrayBuffer view is required');
    const tag = typedTag.call(view);
    const constructor = tag === undefined ? DataView : viewConstructors[tag];
    return {
      buffer: (tag === undefined ? dataBuffer : typedBuffer).call(view),
      byteOffset: (tag === undefined ? dataOffset : typedOffset).call(view),
      byteLength: (tag === undefined ? dataLength : typedLength).call(view),
      constructor: constructor, elementSize: tag === undefined ? 1 : constructor.BYTES_PER_ELEMENT
    };
  }
  function viewFor(request, buffer, byteLength) {
    return new request.viewConstructor(buffer, request.byteOffset, byteLength / request.elementSize);
  }
  function transferPullInto(state, request, buffer) {
    const transferred = transferBuffer.call(buffer === undefined ? request.view.buffer : buffer);
    request.view = viewFor(request, transferred, request.byteLength);
    invalidateByobRequest(state);
  }

  function typeError(message) { return new TypeError(message); }
  function promiseCall(callback, receiver, args) {
    try { return Promise.resolve(callback.apply(receiver, args)); }
    catch (reason) { return Promise.reject(reason); }
  }
  function result(value, done) { return { value: value, done: done }; }
  function requireReadable(stream) {
    const state = readableState.get(stream);
    if (!state) throw typeError('ReadableStream receiver is invalid');
    return state;
  }
  function requireReader(reader) {
    const state = readerState.get(reader);
    if (!state) throw typeError('ReadableStreamDefaultReader receiver is invalid');
    return state;
  }
  function requireController(controller) {
    const state = controllerState.get(controller);
    if (!state) throw typeError('ReadableStreamDefaultController receiver is invalid');
    return state;
  }
  function requireByobRequest(request) {
    const state = byobRequestState.get(request);
    if (!state) throw typeError('ReadableStreamBYOBRequest receiver is invalid');
    return state;
  }
  function byteView(value) {
    const view = describeView(value);
    if (view.byteLength === 0) throw typeError('Byte stream chunk must not be empty');
    return new Uint8Array(transferBuffer.call(view.buffer), view.byteOffset, view.byteLength);
  }
  function filledView(request) {
    return viewFor(request, request.view.buffer, request.offset);
  }
  function copyBytes(target, targetOffset, source, sourceOffset, count) {
    const targetBytes = new Uint8Array(target.buffer, target.byteOffset + targetOffset, count);
    targetBytes.set(new Uint8Array(source.buffer, source.byteOffset + sourceOffset, count));
  }
  function invalidateByobRequest(state) {
    if (!state.byobRequest) return;
    const request = byobRequestState.get(state.byobRequest);
    if (request) request.active = false;
    state.byobRequest = null;
  }
  function currentPullInto(state) {
    const request = state.readRequests.length ? state.readRequests.peek() : null;
    return request && request.kind !== 'default' ? request : null;
  }
  function finishPullInto(state, request, done) {
    transferPullInto(state, request);
    if (state.readRequests.peek() === request) state.readRequests.shift();
    request.resolve(result(filledView(request), done));
  }
  function fillPullInto(state, request, source, sourceOffset) {
    const available = source.length - sourceOffset;
    const capacity = request.byteLength - request.offset;
    let count = Math.min(available, capacity);
    // Commit whole elements only; bytes after the aligned prefix stay queued.
    if (request.offset + count >= request.minimum) count -= (request.offset + count) % request.elementSize;
    copyBytes(request.view, request.offset, source, sourceOffset, count);
    request.offset += count;
    if (request.offset >= request.minimum) finishPullInto(state, request, false);
    return count;
  }
  function drainByteQueue(state) {
    while (state.queue.length && state.readRequests.length) {
      const request = state.readRequests.peek();
      const entry = state.queue.peek();
      if (request.kind === 'default') {
        state.queue.shift();
        state.queueTotalSize -= entry.value.length - entry.offset;
        state.readRequests.shift().resolve(result(entry.value.subarray(entry.offset), false));
      } else {
        const used = fillPullInto(state, request, entry.value, entry.offset);
        entry.offset += used;
        state.queueTotalSize -= used;
        if (entry.offset === entry.value.length) state.queue.shift();
      }
    }
    if (state.closeRequested && state.queue.length === 0) {
      const pending = currentPullInto(state);
      if (pending && pending.offset > 0 && pending.offset < pending.minimum) {
        errorReadable(state, typeError('Byte stream ended before the requested minimum'));
      } else closeReadable(state);
    }
  }
  function settleClosed(state) {
    if (state.reader) {
      const reader = readerState.get(state.reader);
      if (reader) reader.resolveClosed(undefined);
    }
  }
  function settleErrored(state, reason) {
    if (state.reader) {
      const reader = readerState.get(state.reader);
      if (reader) reader.rejectClosed(reason);
    }
  }
  function closeReadable(state) {
    if (state.state !== 'readable') return;
    const pending = currentPullInto(state);
    if (pending && pending.offset % pending.elementSize !== 0) {
      const reason = typeError('Byte stream closed with an incomplete element');
      errorReadable(state, reason);
      throw reason;
    }
    state.state = 'closed';
    // BYOB readers wait for the source to relinquish its pending view with
    // respond(0). Default readers have no caller-supplied buffer to return.
    if (!pending || pending.kind !== 'byob') {
      while (state.readRequests.length) state.readRequests.shift().resolve(result(undefined, true));
      invalidateByobRequest(state);
    }
    settleClosed(state);
  }
  function errorReadable(state, reason) {
    if (state.state !== 'readable') return;
    state.state = 'errored';
    state.storedError = reason;
    state.queue.clear();
    state.queueTotalSize = 0;
    while (state.readRequests.length) state.readRequests.shift().reject(reason);
    invalidateByobRequest(state);
    settleErrored(state, reason);
  }
  function desiredSize(state) {
    if (state.state === 'errored') return null;
    if (state.state === 'closed') return 0;
    return state.highWaterMark - state.queueTotalSize;
  }
  function callPull(state) {
    if (state.state !== 'readable' || state.closeRequested || !state.started || state.pulling || !state.pullAlgorithm) return;
    if (state.readRequests.length === 0 && desiredSize(state) <= 0) return;
    state.pulling = true;
    promiseCall(state.pullAlgorithm, state.underlyingSource, [state.controller]).then(
      function () {
        state.pulling = false;
        if (state.pullAgain) { state.pullAgain = false; callPull(state); }
        else if (state.readRequests.length || desiredSize(state) > 0) callPull(state);
      },
      function (reason) { state.pulling = false; errorReadable(state, reason); }
    );
  }
  function requestPull(state) {
    if (state.pulling) { state.pullAgain = true; return; }
    callPull(state);
  }
  function enqueue(state, chunk) {
    if (state.closeRequested || state.state !== 'readable') throw typeError('Readable stream cannot enqueue');
    if (state.byteStream) {
      const bytes = byteView(chunk);
      const pullInto = currentPullInto(state);
      if (pullInto && state.byobRequest) transferPullInto(state, pullInto);
      state.queue.push({ value: bytes, offset: 0 });
      state.queueTotalSize += bytes.length;
      drainByteQueue(state);
    } else if (state.readRequests.length) {
      state.readRequests.shift().resolve(result(chunk, false));
    } else {
      let size;
      try { size = Number(state.sizeAlgorithm(chunk)); }
      catch (reason) { errorReadable(state, reason); throw reason; }
      if (!Number.isFinite(size) || size < 0) {
        const reason = new RangeError('Chunk size must be finite and non-negative');
        errorReadable(state, reason);
        throw reason;
      }
      state.queue.push({ value: chunk, size: size });
      state.queueTotalSize += size;
    }
    requestPull(state);
  }
  function cancelReadable(state, reason) {
    state.queue.clear();
    state.queueTotalSize = 0;
    if (state.state === 'closed') return Promise.resolve(undefined);
    if (state.state === 'errored') return Promise.reject(state.storedError);
    while (state.readRequests.length) state.readRequests.shift().resolve(result(undefined, true));
    invalidateByobRequest(state);
    closeReadable(state);
    return promiseCall(state.cancelAlgorithm, state.underlyingSource, [reason]).then(function () { return undefined; });
  }
  function readFrom(state) {
    if (state.queue.length) {
      const entry = state.queue.shift();
      state.queueTotalSize -= state.byteStream ? entry.value.length - entry.offset : entry.size;
      while (state.capacityWaiters.length) state.capacityWaiters.shift()(undefined);
      if (state.closeRequested && state.queue.length === 0) closeReadable(state);
      else requestPull(state);
      return Promise.resolve(result(state.byteStream ? entry.value.subarray(entry.offset) : entry.value, false));
    }
    if (state.state === 'closed') return Promise.resolve(result(undefined, true));
    if (state.state === 'errored') return Promise.reject(state.storedError);
    const request = Promise.withResolvers();
    request.kind = 'default';
    if (state.byteStream && state.autoAllocateChunkSize) {
      request.kind = 'auto';
      request.view = new Uint8Array(state.autoAllocateChunkSize);
      request.offset = 0;
      request.minimum = 1;
      request.viewConstructor = Uint8Array;
      request.elementSize = 1;
      request.byteOffset = 0;
      request.byteLength = state.autoAllocateChunkSize;
      request.bufferByteLength = state.autoAllocateChunkSize;
    }
    state.readRequests.push(request);
    while (state.capacityWaiters.length) state.capacityWaiters.shift()(undefined);
    requestPull(state);
    return request.promise;
  }

  function readInto(state, view, minimum) {
    let queued = false;
    try {
      if (!state.byteStream) throw typeError('BYOB requires a byte stream');
      const description = describeView(view);
      if (description.byteLength === 0) throw typeError('BYOB view must not be empty');
      const minElements = minimum === undefined ? 1 : Number(minimum);
      if (!Number.isInteger(minElements) || minElements <= 0 || minElements * description.elementSize > description.byteLength) throw new RangeError('Invalid BYOB minimum');
      if (state.state === 'errored') return Promise.reject(state.storedError);
      const request = Promise.withResolvers();
      request.kind = 'byob';
      request.viewConstructor = description.constructor;
      request.elementSize = description.elementSize;
      request.byteOffset = description.byteOffset;
      request.byteLength = description.byteLength;
      request.bufferByteLength = description.buffer.byteLength;
      request.view = viewFor(request, transferBuffer.call(description.buffer), request.byteLength);
      request.offset = 0;
      request.minimum = minElements * request.elementSize;
      if (state.state === 'closed' && state.readRequests.length === 0) return Promise.resolve(result(filledView(request), true));
      state.readRequests.push(request);
      queued = true;
      drainByteQueue(state);
      requestPull(state);
      return request.promise;
    } catch (reason) {
      if (queued) errorReadable(state, reason);
      return Promise.reject(reason);
    }
  }

  class ReadableStreamDefaultController {
    constructor() { throw typeError('Illegal constructor'); }
    get desiredSize() { return desiredSize(requireController(this)); }
    close() {
      const state = requireController(this);
      if (state.closeRequested || state.state !== 'readable') throw typeError('Readable stream cannot close');
      state.closeRequested = true;
      if (state.queue.length === 0) closeReadable(state);
    }
    enqueue(chunk) { enqueue(requireController(this), chunk); }
    error(reason) { errorReadable(requireController(this), reason); }
  }

  class ReadableStreamBYOBRequest {
    constructor() { throw typeError('Illegal constructor'); }
    get view() {
      const request = requireByobRequest(this);
      if (!request.active) return null;
      return new Uint8Array(request.pullInto.view.buffer, request.pullInto.view.byteOffset + request.pullInto.offset, request.pullInto.view.byteLength - request.pullInto.offset);
    }
    respond(bytesWritten) {
      const request = requireByobRequest(this);
      if (!request.active) throw typeError('BYOB request is no longer active');
      const count = Number(bytesWritten);
      const pullInto = request.pullInto;
      if (pullInto.view.buffer.byteLength === 0) throw typeError('BYOB buffer has been detached');
      if (!Number.isInteger(count) || count < 0 || count > pullInto.byteLength - pullInto.offset) throw new RangeError('Invalid byte count');
      if (request.stream.state === 'closed' ? count !== 0 : count === 0) throw typeError('Byte count does not match stream state');
      transferPullInto(request.stream, pullInto);
      respondPullInto(request.stream, pullInto, count);
    }
    respondWithNewView(view) {
      const request = requireByobRequest(this);
      if (!request.active) throw typeError('BYOB request is no longer active');
      const replacement = describeView(view);
      if (replacement.buffer.byteLength === 0) throw typeError('Replacement buffer has been detached');
      if (request.stream.state === 'closed' ? replacement.byteLength !== 0 : replacement.byteLength === 0) throw typeError('Replacement length does not match stream state');
      const pullInto = request.pullInto;
      if (replacement.byteOffset !== pullInto.byteOffset + pullInto.offset || replacement.buffer.byteLength !== pullInto.bufferByteLength || replacement.byteLength > pullInto.byteLength - pullInto.offset) throw new RangeError('Replacement view must cover the pending BYOB region');
      transferPullInto(request.stream, pullInto, replacement.buffer);
      respondPullInto(request.stream, pullInto, replacement.byteLength);
    }
  }

  function respondPullInto(state, request, count) {
    request.offset += count;
    if (state.state === 'closed') {
      while (state.readRequests.length) finishPullInto(state, state.readRequests.peek(), true);
      return;
    }
    if (request.offset >= request.minimum) {
      const remainder = request.offset % request.elementSize;
      if (remainder) {
        const tail = new Uint8Array(remainder);
        copyBytes(tail, 0, new Uint8Array(request.view.buffer), request.byteOffset + request.offset - remainder, remainder);
        state.queue.push({ value: tail, offset: 0 });
        state.queueTotalSize += remainder;
        request.offset -= remainder;
      }
      finishPullInto(state, request, false);
      drainByteQueue(state);
    }
    requestPull(state);
  }

  class ReadableByteStreamController {
    constructor() { throw typeError('Illegal constructor'); }
    get byobRequest() {
      const state = requireController(this);
      const pullInto = currentPullInto(state);
      if (!pullInto) return null;
      if (!state.byobRequest) {
        const request = Object.create(ReadableStreamBYOBRequest.prototype);
        byobRequestState.set(request, { stream: state, pullInto: pullInto, active: true });
        state.byobRequest = request;
      }
      return state.byobRequest;
    }
    get desiredSize() { return desiredSize(requireController(this)); }
    close() {
      const state = requireController(this);
      if (state.closeRequested || state.state !== 'readable') throw typeError('Readable byte stream cannot close');
      state.closeRequested = true;
      if (state.queue.length === 0) closeReadable(state);
    }
    enqueue(chunk) { enqueue(requireController(this), chunk); }
    error(reason) { errorReadable(requireController(this), reason); }
  }

  class ReadableStreamDefaultReader {
    constructor(stream) {
      const streamState = requireReadable(stream);
      if (streamState.reader) throw typeError('Readable stream is locked');
      const closed = Promise.withResolvers();
      const state = { stream: stream, closed: closed.promise, resolveClosed: closed.resolve, rejectClosed: closed.reject };
      readerState.set(this, state);
      streamState.reader = this;
      if (streamState.state === 'closed') closed.resolve(undefined);
      if (streamState.state === 'errored') closed.reject(streamState.storedError);
    }
    get closed() { return requireReader(this).closed; }
    cancel(reason) {
      const state = requireReader(this);
      if (!state.stream) return Promise.reject(typeError('Reader has no stream'));
      return cancelReadable(requireReadable(state.stream), reason);
    }
    read() {
      const state = requireReader(this);
      if (!state.stream) return Promise.reject(typeError('Reader has no stream'));
      return readFrom(requireReadable(state.stream));
    }
    releaseLock() {
      const state = requireReader(this);
      if (!state.stream) return;
      const streamState = requireReadable(state.stream);
      if (streamState.readRequests.length) throw typeError('Reader has pending reads');
      streamState.reader = null;
      state.stream = null;
      state.rejectClosed(typeError('Reader lock was released'));
    }
  }

  class ReadableStreamBYOBReader {
    constructor(stream) {
      const streamState = requireReadable(stream);
      if (!streamState.byteStream) throw typeError('BYOB requires a byte stream');
      if (streamState.reader) throw typeError('Readable stream is locked');
      const closed = Promise.withResolvers();
      const state = { stream: stream, kind: 'byob', closed: closed.promise, resolveClosed: closed.resolve, rejectClosed: closed.reject };
      readerState.set(this, state);
      streamState.reader = this;
      if (streamState.state === 'closed') closed.resolve(undefined);
      if (streamState.state === 'errored') closed.reject(streamState.storedError);
    }
    get closed() { return requireReader(this).closed; }
    cancel(reason) {
      const state = requireReader(this);
      if (!state.stream) return Promise.reject(typeError('Reader has no stream'));
      return cancelReadable(requireReadable(state.stream), reason);
    }
    read(view, options) {
      const state = requireReader(this);
      if (!state.stream) return Promise.reject(typeError('Reader has no stream'));
      return readInto(requireReadable(state.stream), view, options && options.min);
    }
    releaseLock() {
      const state = requireReader(this);
      if (!state.stream) return;
      const streamState = requireReadable(state.stream);
      if (streamState.readRequests.length) throw typeError('Reader has pending reads');
      streamState.reader = null;
      state.stream = null;
      state.rejectClosed(typeError('Reader lock was released'));
    }
  }

  function genericReader(stream) {
    if (readableState.has(stream)) return new ReadableStreamDefaultReader(stream);
    if (!stream || typeof stream.getReader !== 'function') throw typeError('ReadableStream receiver is invalid');
    return stream.getReader();
  }
  function genericLocked(stream) {
    if (readableState.has(stream)) return requireReadable(stream).reader !== null;
    return !!stream.locked;
  }
  function ignorePipeFailure() { return undefined; }
  function releaseActivePipe(operation) { activePipeThroughOperations.delete(operation); }
  function rethrowPipeFailure(reason) { throw reason; }
  function releasePipe(pipe) {
    try { pipe.reader.releaseLock(); } catch (_) {}
    try { pipe.writer.releaseLock(); } catch (_) {}
  }
  function finishPipe(pipe, value) { releasePipe(pipe); return value; }
  function finishFailedPipe(pipe, reason) { releasePipe(pipe); throw reason; }
  function failPipe(pipe, reason) {
    const cleanup = [];
    if (!pipe.options.preventAbort) cleanup.push(pipe.writer.abort(reason).catch(ignorePipeFailure));
    if (!pipe.options.preventCancel) cleanup.push(pipe.reader.cancel(reason).catch(ignorePipeFailure));
    return Promise.all(cleanup).then(rethrowPipeFailure.bind(undefined, reason));
  }
  function acceptPipeRead(pipe, item) {
    if (item.done) return pipe.options.preventClose ? undefined : pipe.writer.close();
    return pipe.writer.write(item.value).then(continuePipe.bind(undefined, pipe));
  }
  function continuePipe(pipe) {
    if (pipe.options.signal && pipe.options.signal.aborted) return Promise.reject(pipe.options.signal.reason);
    const read = pipe.reader.read();
    return (pipe.aborted ? Promise.race([read, pipe.aborted]) : read).then(acceptPipeRead.bind(undefined, pipe));
  }
  function rejectAbortedPipe(pipe, reject) { reject(pipe.options.signal.reason); }
  function installPipeAbort(pipe, resolve, reject) {
    if (pipe.options.signal.aborted) reject(pipe.options.signal.reason);
    else pipe.options.signal.addEventListener('abort', rejectAbortedPipe.bind(undefined, pipe, reject), { once: true });
  }
  function pipeStreams(source, destination, options) {
    const pipe = { source: source, destination: destination, options: options || {}, reader: null, writer: null, aborted: null };
    try { pipe.reader = genericReader(source); pipe.writer = destination.getWriter(); }
    catch (reason) {
      if (pipe.reader) { try { pipe.reader.releaseLock(); } catch (_) {} }
      return Promise.reject(reason);
    }
    if (pipe.options.signal) pipe.aborted = new Promise(installPipeAbort.bind(undefined, pipe));
    return continuePipe(pipe).catch(failPipe.bind(undefined, pipe)).then(
      finishPipe.bind(undefined, pipe),
      finishFailedPipe.bind(undefined, pipe)
    );
  }

  class ReadableStream {
    constructor(underlyingSource, strategy) {
      if (underlyingSource === undefined) underlyingSource = {};
      if (strategy === undefined) strategy = {};
      if (underlyingSource === null || (typeof underlyingSource !== 'object' && typeof underlyingSource !== 'function')) throw typeError('Underlying source must be an object');
      const type = underlyingSource.type;
      const byteStream = type !== undefined && String(type) === 'bytes';
      if (type !== undefined && !byteStream) throw new RangeError('Unsupported readable stream type');
      if (byteStream && strategy.size !== undefined) throw new RangeError('Byte streams cannot use a size strategy');
      const highWaterMark = strategy.highWaterMark === undefined ? (byteStream ? 0 : 1) : Number(strategy.highWaterMark);
      if (Number.isNaN(highWaterMark) || highWaterMark < 0) throw new RangeError('Invalid highWaterMark');
      const sizeAlgorithm = byteStream ? function (chunk) { return chunk.byteLength; } : strategy.size === undefined ? function () { return 1; } : strategy.size;
      if (typeof sizeAlgorithm !== 'function') throw typeError('Strategy size must be callable');
      let autoAllocateChunkSize = 0;
      if (byteStream && underlyingSource.autoAllocateChunkSize !== undefined) {
        autoAllocateChunkSize = Number(underlyingSource.autoAllocateChunkSize);
        if (!Number.isInteger(autoAllocateChunkSize) || autoAllocateChunkSize <= 0) throw new RangeError('Invalid autoAllocateChunkSize');
      }
      const controller = Object.create(byteStream ? ReadableByteStreamController.prototype : ReadableStreamDefaultController.prototype);
      const state = {
        state: 'readable', storedError: undefined, reader: null, controller: controller,
        byteStream: byteStream, autoAllocateChunkSize: autoAllocateChunkSize, byobRequest: null,
        underlyingSource: underlyingSource,
        pullAlgorithm: typeof underlyingSource.pull === 'function' ? underlyingSource.pull : null,
        cancelAlgorithm: typeof underlyingSource.cancel === 'function' ? underlyingSource.cancel : function () {},
        queue: new StreamQueue(), queueTotalSize: 0, readRequests: new StreamQueue(), highWaterMark: highWaterMark,
        sizeAlgorithm: sizeAlgorithm, started: false, pulling: false, pullAgain: false, closeRequested: false, capacityWaiters: new StreamQueue()
      };
      readableState.set(this, state);
      controllerState.set(controller, state);
      let startResult;
      try { startResult = typeof underlyingSource.start === 'function' ? underlyingSource.start.call(underlyingSource, controller) : undefined; }
      catch (reason) { errorReadable(state, reason); return; }
      Promise.resolve(startResult).then(function () { state.started = true; requestPull(state); }, function (reason) { errorReadable(state, reason); });
    }
    get locked() { return requireReadable(this).reader !== null; }
    cancel(reason) {
      const state = requireReadable(this);
      if (state.reader) return Promise.reject(typeError('Readable stream is locked'));
      return cancelReadable(state, reason);
    }
    getReader(options) {
      if (options !== undefined && options !== null && options.mode !== undefined) {
        if (String(options.mode) === 'byob') return new ReadableStreamBYOBReader(this);
        throw new RangeError('Unsupported reader mode');
      }
      return new ReadableStreamDefaultReader(this);
    }
    pipeThrough(transform, options) {
      requireReadable(this);
      if (!transform) throw typeError('Invalid transform pair');
      const readable = transform.readable;
      const writable = transform.writable;
      if (!readable || !writable) throw typeError('Invalid transform pair');
      const operation = pipeStreams(this, writable, options);
      activePipeThroughOperations.add(operation);
      operation.then(releaseActivePipe.bind(undefined, operation), releaseActivePipe.bind(undefined, operation));
      return readable;
    }
    pipeTo(destination, options) {
      if (!destination || typeof destination.getWriter !== 'function') return Promise.reject(typeError('Invalid writable stream'));
      return pipeStreams(this, destination, options);
    }
    tee() {
      const reader = genericReader(this);
      const byteStream = readableState.has(this) && requireReadable(this).byteStream;
      let leftController;
      let rightController;
      let leftCanceled = false;
      let rightCanceled = false;
      let leftReason;
      let rightReason;
      let sourceFinished = false;
      let cancelStarted = false;
      const cancelCompletion = Promise.withResolvers();
      function cancelSourceWhenUnused() {
        if (sourceFinished) return Promise.resolve(undefined);
        if (leftCanceled && rightCanceled && !cancelStarted) {
          cancelStarted = true;
          reader.cancel([leftReason, rightReason]).then(function () {
            sourceFinished = true; releaseReader(); cancelCompletion.resolve(undefined);
          }, function (reason) {
            sourceFinished = true; releaseReader(); cancelCompletion.reject(reason);
          });
        }
        return cancelCompletion.promise;
      }
      let reading = null;
      function releaseReader() { try { reader.releaseLock(); } catch (_) {} }
      function finishSource(reason, failed) {
        if (sourceFinished) return;
        sourceFinished = true;
        if (failed) {
          if (!leftCanceled) leftController.error(reason);
          if (!rightCanceled) rightController.error(reason);
        } else {
          if (!leftCanceled) closeBranch(leftController);
          if (!rightCanceled) closeBranch(rightController);
        }
        if (!cancelStarted) cancelCompletion.resolve(undefined);
        releaseReader();
      }
      function closeBranch(controller) {
        try {
          controller.close();
          if (byteStream && controller.byobRequest) controller.byobRequest.respond(0);
        } catch (reason) { controller.error(reason); }
      }
      function pullBranch() {
        if (sourceFinished || cancelStarted) return Promise.resolve(undefined);
        if (reading) return reading;
        reading = reader.read().then(function (item) {
          if (sourceFinished || cancelStarted) return;
          if (item.done) { finishSource(undefined, false); return; }
          let rightValue = item.value;
          if (byteStream && !leftCanceled && !rightCanceled) {
            rightValue = new Uint8Array(item.value.byteLength);
            rightValue.set(item.value);
          }
          if (!leftCanceled) leftController.enqueue(item.value);
          if (!rightCanceled) rightController.enqueue(rightValue);
        }).catch(function (reason) { finishSource(reason, true); }).then(function () { reading = null; });
        return reading;
      }
      const branchSource = byteStream ? { type: 'bytes' } : {};
      branchSource.start = function (controller) { leftController = controller; };
      branchSource.pull = pullBranch;
      branchSource.cancel = function (reason) { leftCanceled = true; leftReason = reason; return cancelSourceWhenUnused(); };
      const rightSource = byteStream ? { type: 'bytes' } : {};
      rightSource.start = function (controller) { rightController = controller; };
      rightSource.pull = pullBranch;
      rightSource.cancel = function (reason) { rightCanceled = true; rightReason = reason; return cancelSourceWhenUnused(); };
      const left = new ReadableStream(branchSource);
      const right = new ReadableStream(rightSource);
      reader.closed.catch(function (reason) { finishSource(reason, true); });
      return [left, right];
    }
    values(options) {
      const reader = genericReader(this);
      let finished = false;
      const preventCancel = !!(options && options.preventCancel);
      return {
        next: function () { return reader.read().then(function (item) { if (item.done) { finished = true; reader.releaseLock(); } return item; }); },
        return: function (value) {
          if (finished) return Promise.resolve(result(value, true));
          finished = true;
          const operation = preventCancel ? Promise.resolve(undefined) : reader.cancel(value);
          return operation.then(function () { reader.releaseLock(); return result(value, true); });
        },
        [Symbol.asyncIterator]: function () { return this; }
      };
    }
    [Symbol.asyncIterator]() { return this.values(); }
    static from(iterable) {
      if (iterable == null) throw typeError('Iterable is required');
      const asyncMethod = iterable[Symbol.asyncIterator];
      const syncMethod = iterable[Symbol.iterator];
      const iterator = typeof asyncMethod === 'function' ? asyncMethod.call(iterable) : typeof syncMethod === 'function' ? syncMethod.call(iterable) : null;
      if (!iterator) throw typeError('Value is not iterable');
      return new ReadableStream({
        pull: function (controller) { return Promise.resolve(iterator.next()).then(function (item) {
          if (item.done) controller.close(); else controller.enqueue(item.value);
        }); },
        cancel: function (reason) { return typeof iterator.return === 'function' ? iterator.return(reason) : undefined; }
      });
    }
  }

  function requireWritable(stream) {
    const state = writableState.get(stream);
    if (!state) throw typeError('WritableStream receiver is invalid');
    return state;
  }
  function requireWriter(writer) {
    const state = writerState.get(writer);
    if (!state) throw typeError('WritableStreamDefaultWriter receiver is invalid');
    return state;
  }
  function requireWritableController(controller) {
    const state = writableControllerState.get(controller);
    if (!state) throw typeError('WritableStreamDefaultController receiver is invalid');
    return state;
  }
  function writableDesiredSize(state) {
    if (state.state === 'errored' || state.state === 'erroring') return null;
    if (state.state === 'closed') return 0;
    return state.highWaterMark - state.queueTotalSize;
  }
  function updateWriterReady(state) {
    if (!state.writer) return;
    const writer = writerState.get(state.writer);
    if (!writer) return;
    const backpressure = writableDesiredSize(state) <= 0;
    if (backpressure && !writer.readyPending) {
      const ready = Promise.withResolvers();
      writer.ready = ready.promise;
      writer.resolveReady = ready.resolve;
      writer.readyPending = true;
    } else if (!backpressure && writer.readyPending) {
      writer.readyPending = false;
      writer.resolveReady(undefined);
    }
  }
  function errorWritable(state, reason) {
    if (state.state === 'closed' || state.state === 'errored') return;
    state.state = 'errored';
    state.storedError = reason;
    state.queueTotalSize = 0;
    if (state.writer) {
      const writer = writerState.get(state.writer);
      if (writer) {
        if (writer.readyPending) { writer.readyPending = false; writer.rejectReady(reason); }
        writer.rejectClosed(reason);
      }
    }
  }
  function writeWritable(state, chunk) {
    if (state.state === 'errored') return Promise.reject(state.storedError);
    if (state.state !== 'writable' || state.closeQueued) return Promise.reject(typeError('Writable stream cannot write'));
    let size;
    try { size = Number(state.sizeAlgorithm(chunk)); }
    catch (reason) { errorWritable(state, reason); return Promise.reject(reason); }
    if (!Number.isFinite(size) || size < 0) {
      const reason = new RangeError('Chunk size must be finite and non-negative');
      errorWritable(state, reason);
      return Promise.reject(reason);
    }
    state.queueTotalSize += size;
    updateWriterReady(state);
    const operation = state.chain.then(function () {
      if (state.state === 'errored') throw state.storedError;
      return promiseCall(state.writeAlgorithm, state.underlyingSink, [chunk, state.controller]);
    });
    state.chain = operation.then(function () {
      state.queueTotalSize = Math.max(0, state.queueTotalSize - size);
      updateWriterReady(state);
      return undefined;
    }, function (reason) {
      state.queueTotalSize = Math.max(0, state.queueTotalSize - size);
      errorWritable(state, reason);
      throw reason;
    });
    return state.chain;
  }
  function closeWritable(state) {
    if (state.state === 'errored') return Promise.reject(state.storedError);
    if (state.state !== 'writable' || state.closeQueued) return Promise.reject(typeError('Writable stream cannot close'));
    state.closeQueued = true;
    const operation = state.chain.then(function () {
      if (state.state === 'errored') throw state.storedError;
      return promiseCall(state.closeAlgorithm, state.underlyingSink, []);
    });
    state.chain = operation.then(function () {
      state.state = 'closed';
      if (state.writer) writerState.get(state.writer).resolveClosed(undefined);
      return undefined;
    }, function (reason) { errorWritable(state, reason); throw reason; });
    return state.chain;
  }
  function abortWritable(state, reason) {
    if (state.state === 'closed') return Promise.resolve(undefined);
    if (state.state === 'errored') return Promise.reject(state.storedError);
    state.controllerAbort.abort(reason);
    const operation = promiseCall(state.abortAlgorithm, state.underlyingSink, [reason]);
    errorWritable(state, reason);
    return operation.then(function () { return undefined; });
  }

  class WritableStreamDefaultController {
    constructor() { throw typeError('Illegal constructor'); }
    error(reason) { errorWritable(requireWritableController(this), reason); }
    get signal() { return requireWritableController(this).controllerAbort.signal; }
  }

  class WritableStreamDefaultWriter {
    constructor(stream) {
      const streamState = requireWritable(stream);
      if (streamState.writer) throw typeError('Writable stream is locked');
      const closed = Promise.withResolvers();
      const ready = Promise.withResolvers();
      const state = {
        stream: stream, closed: closed.promise, resolveClosed: closed.resolve, rejectClosed: closed.reject,
        ready: ready.promise, resolveReady: ready.resolve, rejectReady: ready.reject, readyPending: false
      };
      writerState.set(this, state);
      streamState.writer = this;
      if (streamState.state === 'closed') closed.resolve(undefined);
      else if (streamState.state === 'errored') closed.reject(streamState.storedError);
      ready.resolve(undefined);
      updateWriterReady(streamState);
    }
    get closed() { return requireWriter(this).closed; }
    get desiredSize() {
      const state = requireWriter(this);
      if (!state.stream) throw typeError('Writer has no stream');
      return writableDesiredSize(requireWritable(state.stream));
    }
    get ready() { return requireWriter(this).ready; }
    abort(reason) {
      const state = requireWriter(this);
      if (!state.stream) return Promise.reject(typeError('Writer has no stream'));
      return abortWritable(requireWritable(state.stream), reason);
    }
    close() {
      const state = requireWriter(this);
      if (!state.stream) return Promise.reject(typeError('Writer has no stream'));
      return closeWritable(requireWritable(state.stream));
    }
    write(chunk) {
      const state = requireWriter(this);
      if (!state.stream) return Promise.reject(typeError('Writer has no stream'));
      return writeWritable(requireWritable(state.stream), chunk);
    }
    releaseLock() {
      const state = requireWriter(this);
      if (!state.stream) return;
      const streamState = requireWritable(state.stream);
      streamState.writer = null;
      state.stream = null;
      state.rejectClosed(typeError('Writer lock was released'));
      if (state.readyPending) state.rejectReady(typeError('Writer lock was released'));
    }
  }

  class WritableStream {
    constructor(underlyingSink, strategy) {
      if (underlyingSink === undefined) underlyingSink = {};
      if (strategy === undefined) strategy = {};
      if (underlyingSink === null || (typeof underlyingSink !== 'object' && typeof underlyingSink !== 'function')) throw typeError('Underlying sink must be an object');
      if (underlyingSink.type !== undefined) throw new RangeError('Unsupported writable stream type');
      const highWaterMark = strategy.highWaterMark === undefined ? 1 : Number(strategy.highWaterMark);
      if (Number.isNaN(highWaterMark) || highWaterMark < 0) throw new RangeError('Invalid highWaterMark');
      const sizeAlgorithm = strategy.size === undefined ? function () { return 1; } : strategy.size;
      if (typeof sizeAlgorithm !== 'function') throw typeError('Strategy size must be callable');
      const controller = Object.create(WritableStreamDefaultController.prototype);
      const controllerAbort = new AbortController();
      const state = {
        state: 'writable', storedError: undefined, writer: null, controller: controller, controllerAbort: controllerAbort,
        underlyingSink: underlyingSink,
        writeAlgorithm: typeof underlyingSink.write === 'function' ? underlyingSink.write : function () {},
        closeAlgorithm: typeof underlyingSink.close === 'function' ? underlyingSink.close : function () {},
        abortAlgorithm: typeof underlyingSink.abort === 'function' ? underlyingSink.abort : function () {},
        highWaterMark: highWaterMark, sizeAlgorithm: sizeAlgorithm, queueTotalSize: 0, closeQueued: false, chain: null
      };
      writableState.set(this, state);
      writableControllerState.set(controller, state);
      let startResult;
      try { startResult = typeof underlyingSink.start === 'function' ? underlyingSink.start.call(underlyingSink, controller) : undefined; }
      catch (reason) { startResult = Promise.reject(reason); }
      state.chain = Promise.resolve(startResult).catch(function (reason) { errorWritable(state, reason); throw reason; });
    }
    get locked() { return requireWritable(this).writer !== null; }
    abort(reason) {
      const state = requireWritable(this);
      if (state.writer) return Promise.reject(typeError('Writable stream is locked'));
      return abortWritable(state, reason);
    }
    close() {
      const state = requireWritable(this);
      if (state.writer) return Promise.reject(typeError('Writable stream is locked'));
      return closeWritable(state);
    }
    getWriter() { return new WritableStreamDefaultWriter(this); }
  }

  function requireTransform(stream) {
    const state = transformState.get(stream);
    if (!state) throw typeError('TransformStream receiver is invalid');
    return state;
  }
  function requireTransformController(controller) {
    const state = transformControllerState.get(controller);
    if (!state) throw typeError('TransformStreamDefaultController receiver is invalid');
    return state;
  }
  function waitForReadableCapacity(state) {
    const readable = requireReadable(state.readable);
    if (readable.readRequests.length > 0 || desiredSize(readable) > 0) return Promise.resolve(undefined);
    return new Promise(function (resolve) { readable.capacityWaiters.push(resolve); });
  }

  class TransformStreamDefaultController {
    constructor() { throw typeError('Illegal constructor'); }
    get desiredSize() { return desiredSize(requireReadable(requireTransformController(this).readable)); }
    enqueue(chunk) { enqueue(requireReadable(requireTransformController(this).readable), chunk); }
    error(reason) {
      const state = requireTransformController(this);
      errorReadable(requireReadable(state.readable), reason);
      if (state.writable) errorWritable(requireWritable(state.writable), reason);
    }
    terminate() {
      const state = requireTransformController(this);
      const readable = requireReadable(state.readable);
      readable.closeRequested = true;
      if (readable.queue.length === 0) closeReadable(readable);
      if (state.writable) errorWritable(requireWritable(state.writable), typeError('Transform stream was terminated'));
    }
  }

  class TransformStream {
    constructor(transformer, writableStrategy, readableStrategy) {
      if (transformer === undefined) transformer = {};
      if (writableStrategy === undefined) writableStrategy = {};
      if (readableStrategy === undefined) readableStrategy = {};
      if (transformer === null || (typeof transformer !== 'object' && typeof transformer !== 'function')) throw typeError('Transformer must be an object');
      if (transformer.readableType !== undefined || transformer.writableType !== undefined) throw new RangeError('Typed transforms are unsupported');
      let readableController;
      const effectiveReadableStrategy = Object.assign({}, readableStrategy);
      if (effectiveReadableStrategy.highWaterMark === undefined) effectiveReadableStrategy.highWaterMark = 0;
      const readable = new ReadableStream({ start: function (controller) { readableController = controller; } }, effectiveReadableStrategy);
      const controller = Object.create(TransformStreamDefaultController.prototype);
      const state = { readable: readable, writable: null, controller: controller, transformer: transformer };
      transformControllerState.set(controller, state);
      const writable = new WritableStream({
        start: function () {
          return promiseCall(typeof transformer.start === 'function' ? transformer.start : function () {}, transformer, [controller]).catch(function (reason) {
            controller.error(reason);
            throw reason;
          });
        },
        write: function (chunk) {
          return waitForReadableCapacity(state).then(function () {
            return promiseCall(typeof transformer.transform === 'function' ? transformer.transform : function (value, target) { target.enqueue(value); }, transformer, [chunk, controller]);
          }).catch(function (reason) {
            controller.error(reason);
            throw reason;
          });
        },
        close: function () {
          return promiseCall(typeof transformer.flush === 'function' ? transformer.flush : function () {}, transformer, [controller]).then(function () {
            const readableStateValue = requireReadable(readable);
            if (!readableStateValue.closeRequested && readableStateValue.state === 'readable') {
              readableStateValue.closeRequested = true;
              if (readableStateValue.queue.length === 0) closeReadable(readableStateValue);
            }
          }).catch(function (reason) {
            controller.error(reason);
            throw reason;
          });
        },
        abort: function (reason) { errorReadable(requireReadable(readable), reason); }
      }, writableStrategy);
      state.writable = writable;
      transformState.set(this, state);
    }
    get readable() { return requireTransform(this).readable; }
    get writable() { return requireTransform(this).writable; }
  }

  Object.defineProperty(ReadableStream.prototype, Symbol.toStringTag, { value: 'ReadableStream', configurable: true });
  Object.defineProperty(ReadableStream, 'length', { value: 0 });
  Object.defineProperty(ReadableStreamDefaultReader.prototype, Symbol.toStringTag, { value: 'ReadableStreamDefaultReader', configurable: true });
  Object.defineProperty(ReadableStreamDefaultController.prototype, Symbol.toStringTag, { value: 'ReadableStreamDefaultController', configurable: true });
  Object.defineProperty(ReadableStreamBYOBReader.prototype, Symbol.toStringTag, { value: 'ReadableStreamBYOBReader', configurable: true });
  Object.defineProperty(ReadableStreamBYOBRequest.prototype, Symbol.toStringTag, { value: 'ReadableStreamBYOBRequest', configurable: true });
  Object.defineProperty(ReadableByteStreamController.prototype, Symbol.toStringTag, { value: 'ReadableByteStreamController', configurable: true });
  Object.defineProperty(WritableStream.prototype, Symbol.toStringTag, { value: 'WritableStream', configurable: true });
  Object.defineProperty(WritableStream, 'length', { value: 0 });
  Object.defineProperty(WritableStreamDefaultWriter.prototype, Symbol.toStringTag, { value: 'WritableStreamDefaultWriter', configurable: true });
  Object.defineProperty(WritableStreamDefaultController.prototype, Symbol.toStringTag, { value: 'WritableStreamDefaultController', configurable: true });
  Object.defineProperty(TransformStream.prototype, Symbol.toStringTag, { value: 'TransformStream', configurable: true });
  Object.defineProperty(TransformStream, 'length', { value: 0 });
  Object.defineProperty(TransformStreamDefaultController.prototype, Symbol.toStringTag, { value: 'TransformStreamDefaultController', configurable: true });
  Object.defineProperty(global, 'ReadableStream', { value: ReadableStream, writable: true, configurable: true });
  Object.defineProperty(global, 'ReadableStreamDefaultReader', { value: ReadableStreamDefaultReader, writable: true, configurable: true });
  Object.defineProperty(global, 'ReadableStreamDefaultController', { value: ReadableStreamDefaultController, writable: true, configurable: true });
  Object.defineProperty(global, 'ReadableStreamBYOBReader', { value: ReadableStreamBYOBReader, writable: true, configurable: true });
  Object.defineProperty(global, 'ReadableStreamBYOBRequest', { value: ReadableStreamBYOBRequest, writable: true, configurable: true });
  Object.defineProperty(global, 'ReadableByteStreamController', { value: ReadableByteStreamController, writable: true, configurable: true });
  Object.defineProperty(global, 'WritableStream', { value: WritableStream, writable: true, configurable: true });
  Object.defineProperty(global, 'WritableStreamDefaultWriter', { value: WritableStreamDefaultWriter, writable: true, configurable: true });
  Object.defineProperty(global, 'WritableStreamDefaultController', { value: WritableStreamDefaultController, writable: true, configurable: true });
  Object.defineProperty(global, 'TransformStream', { value: TransformStream, writable: true, configurable: true });
  Object.defineProperty(global, 'TransformStreamDefaultController', { value: TransformStreamDefaultController, writable: true, configurable: true });
})(globalThis);
