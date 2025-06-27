import "core-js/modules/es.error.cause.js";
import "core-js/modules/es.array.push.js";
import * as Comlink from "@notionhq/shared/comlink";
import { OPFS_DIRECTORIES } from "@notionhq/shared/OPFS/constants";
import { getOPFSMeetingNotesCacheUpdateChannelForBlock, parseOPFSMeetingNotesCacheKey } from "@notionhq/shared/OPFS/helpers";
const DEBUG_NAMESPACE = "notion:OPFS:MeetingNotesCacheWorker";
/**
 * Cache implementation using Origin Private File System (OPFS)
 * Provides persistent local file storage for meeting notes
 */
class OPFSMeetingNotesCacheWorker {
  constructor() {
    this.cacheDirPromise = void 0;
    this.syncHandle = void 0;
    this.key = void 0;
    void this.getCacheDir().catch(error => {});
  }

  /**
   * Get the cache directory
   * @returns The cache directory
   */
  async getCacheDir() {
    if (this.cacheDirPromise) {
      return this.cacheDirPromise;
    }
    this.cacheDirPromise = navigator.storage.getDirectory().then(root => root.getDirectoryHandle(OPFS_DIRECTORIES.MEETING_NOTES_CACHE, {
      create: true
    }));
    return this.cacheDirPromise;
  }

  /**
   * Writes (appends) a chunk of audio data to a file in the cache using SyncAccessHandle.
   * If the file doesn't exist, it's created. Subsequent calls append data.
   * @param key - The key identifying the audio file.
   * @param audioData - The audio data to append.
   * @throws {Error} If writing fails.
   */
  async write(key, data) {
    try {
      // Key changed? Close the old handle first.
      if (key !== this.key && this.syncHandle) {
        this.syncHandle.close();
        this.syncHandle = undefined;
        this.key = undefined;
      }
      let newFileCreated = false;
      if (!this.syncHandle) {
        const cacheDir = await this.getCacheDir();
        try {
          const existingFileHandle = await cacheDir.getFileHandle(key);
          this.syncHandle = await existingFileHandle.createSyncAccessHandle();
          this.key = key;
        } catch (error) {
          try {
            const newFileHandle = await cacheDir.getFileHandle(key, {
              create: true
            });
            this.syncHandle = await newFileHandle.createSyncAccessHandle();
            this.key = key;
            newFileCreated = true;
          } catch (error) {
            throw error;
          }
        }
      }

      // Get current size to append
      const currentSize = this.syncHandle.getSize();
      this.syncHandle.write(data, {
        at: currentSize
      });
      this.syncHandle.flush();
      const parsedKey = parseOPFSMeetingNotesCacheKey(key);
      if (!(parsedKey instanceof Error)) {
        const updateChannel = getOPFSMeetingNotesCacheUpdateChannelForBlock(parsedKey.blockId);
        updateChannel.postMessage(newFileCreated ? "file_added" : "file_updated");
        updateChannel.close();
      }
    } catch (error) {
      this.close();
      throw error;
    }
  }

  /**
   * Reads audio data from the cache as a buffer.
   * @param key - The key to read the audio data from
   * @returns ArrayBuffer of the audio data.
   * @throws {Error} If reading fails or the file doesn't exist
   */
  async readBuffer(key) {
    const cacheDir = await this.getCacheDir();
    const handle = await cacheDir.getFileHandle(key);
    const file = await handle.getFile();
    const buffer = await file.arrayBuffer();
    return Comlink.transfer(buffer, [buffer]);
  }

  /**
   * Explicitly closes the currently open FileSystemSyncAccessHandle, if any.
   */
  close() {
    if (!this.syncHandle) {
      return;
    }
    this.syncHandle.close();
    this.syncHandle = undefined;
    this.key = undefined;
  }

  /**
   * Deletes a file from the cache
   * @param key - The key to delete
   * @throws {Error} If deleting fails or the file doesn't exist
   */
  async delete(key) {
    // If deleting the currently open file, close its handle first.
    if (key === this.key && this.syncHandle) {
      this.syncHandle.close();
      this.syncHandle = undefined;
      this.key = undefined;
    }
    const cacheDir = await this.getCacheDir();
    await cacheDir.removeEntry(key, {
      recursive: true
    });
    const parsedKey = parseOPFSMeetingNotesCacheKey(key);
    if (!(parsedKey instanceof Error)) {
      const updateChannel = getOPFSMeetingNotesCacheUpdateChannelForBlock(parsedKey.blockId);
      updateChannel.postMessage("file_removed");
      updateChannel.close();
    }
  }

  /**
   * Deletes all files from the cache
   * @throws {Error} If deleting fails
   */
  async deleteAll(keyContains) {
    const cacheDir = await this.getCacheDir();
    for await (const handle of cacheDir.values()) {
      if (keyContains !== undefined && !handle.name.includes(keyContains)) {
        continue;
      }
      await this.delete(handle.name);
    }
  }
  async listFiles(keyContains) {
    const cacheDir = await this.getCacheDir();
    const files = [];
    for await (const handle of cacheDir.values()) {
      if (handle.kind === "directory" || keyContains && !handle.name.includes(keyContains)) {
        continue;
      }
      files.push(await handle.getFile());
    }
    return files;
  }
  enableDebug() {}
  disableDebug() {}
}
Comlink.expose(new OPFSMeetingNotesCacheWorker());