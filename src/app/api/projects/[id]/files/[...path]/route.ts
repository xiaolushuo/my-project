import { NextRequest, NextResponse } from 'next/server'
import { getFileContent, updateFileContent } from '@/lib/file-utils'
import { join } from 'path'

const EXTRACT_DIR = join(process.cwd(), 'extracted')

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string; path: string[] } }
) {
  try {
    const { id, path } = params
    const filePath = join(EXTRACT_DIR, id, ...path)

    const content = await getFileContent(filePath)
    
    return NextResponse.json({
      success: true,
      content: content,
      filePath: filePath,
    })
  } catch (error) {
    console.error('Error getting file content:', error)
    return NextResponse.json(
      { error: 'Failed to get file content' },
      { status: 500 }
    )
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string; path: string[] } }
) {
  try {
    const { id, path } = params
    const filePath = join(EXTRACT_DIR, id, ...path)
    
    const body = await request.json()
    const { content } = body

    if (content === undefined) {
      return NextResponse.json(
        { error: 'Content is required' },
        { status: 400 }
      )
    }

    await updateFileContent(filePath, content)
    
    return NextResponse.json({
      success: true,
      message: 'File updated successfully',
      filePath: filePath,
    })
  } catch (error) {
    console.error('Error updating file content:', error)
    return NextResponse.json(
      { error: 'Failed to update file content' },
      { status: 500 }
    )
  }
}