import { readdir, readFile, writeFile, stat, unlink, rmdir } from 'fs/promises'
import { join } from 'path'
import AdmZip from 'adm-zip'

const UPLOAD_DIR = join(process.cwd(), 'uploads')
const EXTRACT_DIR = join(process.cwd(), 'extracted')

export interface UploadedFile {
  id: string
  fileName: string
  uploadPath: string
  extractPath: string
  uploadedAt: string
  fileSize: number
  extractedFiles: string[]
  extractedFileCount: number
}

export interface FileInfo {
  name: string
  path: string
  size: number
  isDirectory: boolean
  lastModified: Date
  children?: FileInfo[]
}

export async function getUploadedFiles(): Promise<UploadedFile[]> {
  try {
    const files = await readdir(EXTRACT_DIR)
    const uploadedFiles: UploadedFile[] = []

    for (const file of files) {
      const extractPath = join(EXTRACT_DIR, file)
      const uploadPath = join(UPLOAD_DIR, file)
      
      try {
        const stats = await stat(extractPath)
        const uploadedFile: UploadedFile = {
          id: file,
          fileName: file, // This would be stored in metadata in a real app
          uploadPath,
          extractPath,
          uploadedAt: stats.birthtime.toISOString(),
          fileSize: 0, // This would be stored in metadata
          extractedFiles: [],
          extractedFileCount: 0,
        }

        // Get list of extracted files
        const extractedFiles = await getDirectoryContents(extractPath)
        uploadedFile.extractedFiles = extractedFiles.map(f => f.name)
        uploadedFile.extractedFileCount = extractedFiles.length

        uploadedFiles.push(uploadedFile)
      } catch (error) {
        console.error(`Error reading file ${file}:`, error)
      }
    }

    return uploadedFiles.sort((a, b) => 
      new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime()
    )
  } catch (error) {
    console.error('Error reading uploaded files:', error)
    return []
  }
}

export async function getDirectoryContents(dirPath: string): Promise<FileInfo[]> {
  try {
    const items = await readdir(dirPath, { withFileTypes: true })
    const contents: FileInfo[] = []

    for (const item of items) {
      const fullPath = join(dirPath, item.name)
      const stats = await stat(fullPath)
      
      const fileInfo: FileInfo = {
        name: item.name,
        path: fullPath,
        size: stats.size,
        isDirectory: item.isDirectory(),
        lastModified: stats.mtime,
      }

      if (item.isDirectory()) {
        fileInfo.children = await getDirectoryContents(fullPath)
      }

      contents.push(fileInfo)
    }

    return contents.sort((a, b) => {
      if (a.isDirectory && !b.isDirectory) return -1
      if (!a.isDirectory && b.isDirectory) return 1
      return a.name.localeCompare(b.name)
    })
  } catch (error) {
    console.error('Error reading directory contents:', error)
    return []
  }
}

export async function deleteUploadedFile(id: string): Promise<boolean> {
  try {
    const extractPath = join(EXTRACT_DIR, id)
    const uploadPath = join(UPLOAD_DIR, id)

    // Delete extracted files and directory
    await deleteDirectory(extractPath)

    // Delete uploaded file
    try {
      await unlink(uploadPath)
    } catch (error) {
      // Upload file might not exist, which is okay
      console.log('Upload file not found:', uploadPath)
    }

    return true
  } catch (error) {
    console.error('Error deleting uploaded file:', error)
    return false
  }
}

async function deleteDirectory(dirPath: string): Promise<void> {
  try {
    const items = await readdir(dirPath, { withFileTypes: true })
    
    for (const item of items) {
      const fullPath = join(dirPath, item.name)
      
      if (item.isDirectory()) {
        await deleteDirectory(fullPath)
      } else {
        await unlink(fullPath)
      }
    }
    
    await rmdir(dirPath)
  } catch (error) {
    console.error('Error deleting directory:', error)
    throw error
  }
}

export async function createZipFromDirectory(dirPath: string, outputPath: string): Promise<void> {
  try {
    const zip = new AdmZip()
    
    // Add all files from directory to zip
    const addFilesToZip = async (currentPath: string, zipPath: string = '') => {
      const items = await readdir(currentPath, { withFileTypes: true })
      
      for (const item of items) {
        const fullPath = join(currentPath, item.name)
        const relativePath = zipPath ? join(zipPath, item.name) : item.name
        
        if (item.isDirectory()) {
          await addFilesToZip(fullPath, relativePath)
        } else {
          const content = await readFile(fullPath)
          zip.addFile(relativePath, content)
        }
      }
    }
    
    await addFilesToZip(dirPath)
    zip.writeZip(outputPath)
  } catch (error) {
    console.error('Error creating zip file:', error)
    throw error
  }
}

export async function getFileContent(filePath: string): Promise<string> {
  try {
    const content = await readFile(filePath, 'utf-8')
    return content
  } catch (error) {
    console.error('Error reading file content:', error)
    throw error
  }
}

export async function updateFileContent(filePath: string, content: string): Promise<void> {
  try {
    await writeFile(filePath, content, 'utf-8')
  } catch (error) {
    console.error('Error updating file content:', error)
    throw error
  }
}