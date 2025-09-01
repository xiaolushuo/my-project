import { NextRequest, NextResponse } from 'next/server'
import { getDirectoryContents, deleteUploadedFile } from '@/lib/file-utils'
import { join } from 'path'

const EXTRACT_DIR = join(process.cwd(), 'extracted')

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params
    const extractPath = join(EXTRACT_DIR, id)

    const contents = await getDirectoryContents(extractPath)
    
    return NextResponse.json({
      success: true,
      projectId: id,
      contents: contents,
      extractPath: extractPath,
    })
  } catch (error) {
    console.error('Error getting project contents:', error)
    return NextResponse.json(
      { error: 'Failed to get project contents' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params
    
    const success = await deleteUploadedFile(id)
    
    if (success) {
      return NextResponse.json({
        success: true,
        message: 'Project deleted successfully',
        projectId: id,
      })
    } else {
      return NextResponse.json(
        { error: 'Failed to delete project' },
        { status: 500 }
      )
    }
  } catch (error) {
    console.error('Error deleting project:', error)
    return NextResponse.json(
      { error: 'Failed to delete project' },
      { status: 500 }
    )
  }
}