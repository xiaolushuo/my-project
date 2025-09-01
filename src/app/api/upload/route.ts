import { NextRequest, NextResponse } from 'next/server'
import AdmZip from 'adm-zip'
import { writeFile, mkdir, access, constants } from 'fs/promises'
import { join } from 'path'
import { randomUUID } from 'crypto'

const UPLOAD_DIR = join(process.cwd(), 'uploads')
const EXTRACT_DIR = join(process.cwd(), 'extracted')

export async function POST(request: NextRequest) {
  try {
    // Ensure upload and extract directories exist
    try {
      await access(UPLOAD_DIR)
    } catch {
      await mkdir(UPLOAD_DIR, { recursive: true })
    }

    try {
      await access(EXTRACT_DIR)
    } catch {
      await mkdir(EXTRACT_DIR, { recursive: true })
    }

    const formData = await request.formData()
    const file = formData.get('file') as File

    if (!file) {
      return NextResponse.json(
        { error: 'No file provided' },
        { status: 400 }
      )
    }

    // Check file type
    if (!file.name.toLowerCase().endsWith('.zip')) {
      return NextResponse.json(
        { error: 'Only .zip files are allowed' },
        { status: 400 }
      )
    }

    // Check file size (100MB limit)
    const maxSize = 100 * 1024 * 1024 // 100MB
    if (file.size > maxSize) {
      return NextResponse.json(
        { error: 'File size exceeds 100MB limit' },
        { status: 400 }
      )
    }

    // Generate unique filename
    const uniqueId = randomUUID()
    const uploadFileName = `${uniqueId}-${file.name}`
    const uploadPath = join(UPLOAD_DIR, uploadFileName)
    const extractPath = join(EXTRACT_DIR, uniqueId)

    // Convert file to buffer
    const bytes = await file.arrayBuffer()
    const buffer = Buffer.from(bytes)

    // Save uploaded file
    await writeFile(uploadPath, buffer)

    // Extract zip file
    const zip = new AdmZip(buffer)
    
    // Create extraction directory
    await mkdir(extractPath, { recursive: true })
    
    // Extract all files
    zip.extractAllTo(extractPath, true)

    // Get list of extracted files
    const extractedFiles = zip.getEntries().map(entry => entry.entryName)

    return NextResponse.json({
      success: true,
      message: 'File uploaded and extracted successfully',
      fileName: file.name,
      fileSize: file.size,
      uploadPath: uploadPath,
      extractPath: extractPath,
      extractedFiles: extractedFiles,
      extractedFileCount: extractedFiles.length,
      uploadId: uniqueId,
    })

  } catch (error) {
    console.error('Upload error:', error)
    return NextResponse.json(
      { error: 'Failed to upload and extract file' },
      { status: 500 }
    )
  }
}

export async function GET() {
  return NextResponse.json({
    message: 'Upload endpoint is ready',
    maxFileSize: '100MB',
    allowedTypes: ['.zip'],
  })
}