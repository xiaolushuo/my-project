import { NextRequest, NextResponse } from 'next/server'
import { writeFile, mkdir, access, constants, readFile, unlink } from 'fs/promises'
import { join } from 'path'
import { randomUUID } from 'crypto'
import AdmZip from 'adm-zip'

const EXTRACT_DIR = join(process.cwd(), 'extracted')
const PACKAGE_DIR = join(process.cwd(), 'packages')

export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const projectId = params.id
    const projectPath = join(EXTRACT_DIR, projectId)

    // 检查项目是否存在
    try {
      await access(projectPath)
    } catch {
      return NextResponse.json(
        { error: 'Project not found' },
        { status: 404 }
      )
    }

    // 确保packages目录存在
    try {
      await access(PACKAGE_DIR)
    } catch {
      await mkdir(PACKAGE_DIR, { recursive: true })
    }

    // 生成唯一的包ID
    const packageId = randomUUID()
    const packageFileName = `project-${projectId}-${packageId.substring(0, 8)}.zip`
    const packagePath = join(PACKAGE_DIR, packageFileName)

    // 创建ZIP文件
    const zip = new AdmZip()

    // 添加项目文件到ZIP
    await addProjectFilesToZip(zip, projectPath, projectId)

    // 生成包信息
    const packageInfo = {
      id: packageId,
      projectId: projectId,
      fileName: packageFileName,
      packageName: `Project ${projectId}`,
      version: '1.0.0',
      description: 'Uploaded project package',
      createdAt: new Date().toISOString(),
      fileSize: 0,
      fileCount: 0
    }

    // 添加包信息文件
    zip.addFile('package.json', Buffer.from(JSON.stringify(packageInfo, null, 2)))

    // 添加README文件
    const readmeContent = generateReadmeContent(projectId)
    zip.addFile('README.md', Buffer.from(readmeContent))

    // 写入ZIP文件
    zip.writeZip(packagePath)

    // 获取文件信息
    const stats = await readFile(packagePath)
    packageInfo.fileSize = stats.length
    packageInfo.fileCount = zip.getEntryCount()

    // 返回包信息
    return NextResponse.json({
      success: true,
      package: packageInfo,
      downloadUrl: `/api/projects/${projectId}/package/download/${packageId}`
    })

  } catch (error) {
    console.error('Package creation error:', error)
    return NextResponse.json(
      { error: 'Failed to create package' },
      { status: 500 }
    )
  }
}

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const projectId = params.id
    const projectPath = join(EXTRACT_DIR, projectId)

    // 检查项目是否存在
    try {
      await access(projectPath)
    } catch {
      return NextResponse.json(
        { error: 'Project not found' },
        { status: 404 }
      )
    }

    // 获取项目信息
    const packageInfo = {
      projectId: projectId,
      packageName: `Project ${projectId}`,
      version: '1.0.0',
      description: 'Uploaded project package',
      estimatedSize: 'Unknown',
      canPackage: true
    }

    return NextResponse.json({
      success: true,
      package: packageInfo
    })

  } catch (error) {
    console.error('Package info error:', error)
    return NextResponse.json(
      { error: 'Failed to get package info' },
      { status: 500 }
    )
  }
}

// 下载包的端点
export async function GET_DOWNLOAD(
  request: NextRequest,
  { params }: { params: { id: string; packageId: string[] } }
) {
  try {
    const projectId = params.id
    const packageId = params.packageId[0]
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

// 辅助函数：递归添加项目文件到ZIP
async function addProjectFilesToZip(zip: AdmZip, dirPath: string, basePath: string) {
  const { readdir, stat } = await import('fs/promises')
  
  const items = await readdir(dirPath, { withFileTypes: true })
  
  for (const item of items) {
    const fullPath = join(dirPath, item.name)
    const relativePath = join(basePath, item.name)
    
    if (item.isDirectory()) {
      // 递归处理子目录
      await addProjectFilesToZip(zip, fullPath, relativePath)
    } else {
      // 添加文件到ZIP
      try {
        const fileContent = await readFile(fullPath)
        zip.addFile(relativePath, fileContent)
      } catch (error) {
        console.error(`Failed to add file ${relativePath}:`, error)
      }
    }
  }
}

// 生成README内容
function generateReadmeContent(projectId: string): string {
  return `# Project ${projectId}

This is an uploaded project package from the Code Upload Portal.

## Project Information
- **Project ID**: ${projectId}
- **Packaged Date**: ${new Date().toLocaleDateString()}
- **Version**: 1.0.0

## Contents
This package contains all the files from the uploaded project.

## How to Use
1. Extract the ZIP file to your desired location
2. Open the project files in your preferred development environment
3. Start using the project

## Notes
- This project was uploaded through the Code Upload Portal
- All files are preserved in their original structure
- No modifications were made to the project files

## Support
If you encounter any issues with this project, please refer to the original project documentation or contact the project uploader.

---
Generated by Code Upload Portal
`
}