import { NextRequest, NextResponse } from 'next/server'
import { readFile, access, constants, unlink } from 'fs/promises'
import { join } from 'path'

const PACKAGE_DIR = join(process.cwd(), 'packages')

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string; path: string[] } }
) {
  try {
    const projectId = params.id
    const packageId = params.path[0]
    const packageFileName = `project-${projectId}-${packageId.substring(0, 8)}.zip`
    const packagePath = join(PACKAGE_DIR, packageFileName)

    // 检查包文件是否存在
    try {
      await access(packagePath)
    } catch {
      return NextResponse.json(
        { error: 'Package not found' },
        { status: 404 }
      )
    }

    // 读取包文件
    const packageFile = await readFile(packagePath)

    // 设置响应头
    const headers = new Headers()
    headers.set('Content-Type', 'application/zip')
    headers.set('Content-Disposition', `attachment; filename="${packageFileName}"`)
    headers.set('Cache-Control', 'no-cache, no-store, must-revalidate')
    headers.set('Pragma', 'no-cache')
    headers.set('Expires', '0')

    return new NextResponse(packageFile, {
      status: 200,
      headers
    })

  } catch (error) {
    console.error('Package download error:', error)
    return NextResponse.json(
      { error: 'Failed to download package' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string; path: string[] } }
) {
  try {
    const projectId = params.id
    const packageId = params.path[0]
    const packageFileName = `project-${projectId}-${packageId.substring(0, 8)}.zip`
    const packagePath = join(PACKAGE_DIR, packageFileName)

    // 检查包文件是否存在
    try {
      await access(packagePath)
    } catch {
      return NextResponse.json(
        { error: 'Package not found' },
        { status: 404 }
      )
    }

    // 删除包文件
    await unlink(packagePath)

    return NextResponse.json({
      success: true,
      message: 'Package deleted successfully',
      packageId: packageId
    })

  } catch (error) {
    console.error('Package deletion error:', error)
    return NextResponse.json(
      { error: 'Failed to delete package' },
      { status: 500 }
    )
  }
}