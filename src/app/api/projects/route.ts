import { NextRequest, NextResponse } from 'next/server'
import { getUploadedFiles } from '@/lib/file-utils'

export async function GET() {
  try {
    const files = await getUploadedFiles()
    return NextResponse.json({
      success: true,
      files: files,
      count: files.length,
    })
  } catch (error) {
    console.error('Error getting uploaded files:', error)
    return NextResponse.json(
      { error: 'Failed to get uploaded files' },
      { status: 500 }
    )
  }
}