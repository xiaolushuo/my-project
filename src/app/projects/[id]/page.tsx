"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { ScrollArea } from "@/components/ui/scroll-area"
import { 
  ArrowLeft, 
  FolderOpen, 
  FileText, 
  FileCode, 
  FileImage,
  File,
  Search,
  Save,
  X,
  Loader2,
  AlertCircle
} from "lucide-react"
import { toast } from "@/hooks/use-toast"
import Link from "next/link"

interface FileInfo {
  name: string
  path: string
  size: number
  isDirectory: boolean
  lastModified: Date
  children?: FileInfo[]
}

interface Project {
  id: string
  fileName: string
  uploadedAt: string
  fileSize: number
  extractedFileCount: number
}

export default function ProjectPage() {
  const params = useParams()
  const router = useRouter()
  const projectId = params.id as string

  const [project, setProject] = useState<Project | null>(null)
  const [files, setFiles] = useState<FileInfo[]>([])
  const [selectedFile, setSelectedFile] = useState<FileInfo | null>(null)
  const [fileContent, setFileContent] = useState("")
  const [loading, setLoading] = useState(true)
  const [loadingContent, setLoadingContent] = useState(false)
  const [saving, setSaving] = useState(false)
  const [searchTerm, setSearchTerm] = useState("")
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadProject()
  }, [projectId])

  const loadProject = async () => {
    try {
      setLoading(true)
      setError(null)

      const response = await fetch(`/api/projects/${projectId}`)
      if (!response.ok) {
        throw new Error('Project not found')
      }
      
      const data = await response.json()
      setFiles(data.contents || [])
      
      // Set project info (we'll get this from the files structure)
      setProject({
        id: projectId,
        fileName: `Project ${projectId}`,
        uploadedAt: new Date().toISOString(),
        fileSize: 0,
        extractedFileCount: data.contents?.length || 0,
      })

    } catch (error) {
      setError('Failed to load project')
      toast({
        title: "Error",
        description: "Failed to load project",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const loadFileContent = async (file: FileInfo) => {
    if (file.isDirectory) return

    try {
      setLoadingContent(true)
      setSelectedFile(file)
      
      // Get relative path from the project root
      const relativePath = file.path.replace(`/extracted/${projectId}/`, '')
      const response = await fetch(`/api/projects/${projectId}/files/${relativePath}`)
      
      if (!response.ok) {
        throw new Error('Failed to load file content')
      }
      
      const data = await response.json()
      setFileContent(data.content || "")

    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to load file content",
        variant: "destructive",
      })
    } finally {
      setLoadingContent(false)
    }
  }

  const saveFileContent = async () => {
    if (!selectedFile) return

    try {
      setSaving(true)
      
      // Get relative path from the project root
      const relativePath = selectedFile.path.replace(`/extracted/${projectId}/`, '')
      const response = await fetch(`/api/projects/${projectId}/files/${relativePath}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: fileContent,
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to save file')
      }

      toast({
        title: "Success",
        description: "File saved successfully",
      })

    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to save file",
        variant: "destructive",
      })
    } finally {
      setSaving(false)
    }
  }

  const getFileIcon = (fileName: string, isDirectory: boolean) => {
    if (isDirectory) return <FolderOpen className="h-4 w-4" />
    
    const ext = fileName.split('.').pop()?.toLowerCase()
    
    switch (ext) {
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
      case 'py':
      case 'java':
      case 'cpp':
      case 'c':
      case 'go':
      case 'rs':
        return <FileCode className="h-4 w-4" />
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
      case 'webp':
        return <FileImage className="h-4 w-4" />
      case 'md':
      case 'txt':
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return <FileText className="h-4 w-4" />
      default:
        return <File className="h-4 w-4" />
    }
  }

  const filterFiles = (files: FileInfo[], term: string): FileInfo[] => {
    if (!term) return files
    
    return files.filter(file => {
      if (file.name.toLowerCase().includes(term.toLowerCase())) {
        return true
      }
      
      if (file.isDirectory && file.children) {
        const filteredChildren = filterFiles(file.children, term)
        if (filteredChildren.length > 0) {
          file.children = filteredChildren
          return true
        }
      }
      
      return false
    })
  }

  const renderFileTree = (files: FileInfo[], level = 0) => {
    return files.map((file) => (
      <div key={file.path}>
        <div
          className={`flex items-center gap-2 p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded cursor-pointer ${
            selectedFile?.path === file.path ? 'bg-blue-50 dark:bg-blue-950' : ''
          }`}
          style={{ paddingLeft: `${level * 16 + 8}px` }}
          onClick={() => loadFileContent(file)}
        >
          {getFileIcon(file.name, file.isDirectory)}
          <span className="text-sm truncate flex-1">{file.name}</span>
          {!file.isDirectory && (
            <Badge variant="outline" className="text-xs">
              {(file.size / 1024).toFixed(1)} KB
            </Badge>
          )}
        </div>
        
        {file.isDirectory && file.children && (
          <div>
            {renderFileTree(file.children, level + 1)}
          </div>
        )}
      </div>
    ))
  }

  const filteredFiles = filterFiles([...files], searchTerm)

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-slate-600 dark:text-slate-300">Loading project...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 flex items-center justify-center">
        <Card className="w-full max-w-md">
          <CardContent className="flex flex-col items-center justify-center py-12">
            <AlertCircle className="h-12 w-12 text-red-600 mb-4" />
            <h3 className="text-lg font-medium text-slate-900 dark:text-slate-100 mb-2">
              {error}
            </h3>
            <p className="text-slate-600 dark:text-slate-300 text-center mb-4">
              The project you're looking for might have been deleted or doesn't exist.
            </p>
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => router.back()}>
                Go Back
              </Button>
              <Button asChild>
                <Link href="/projects">
                  View All Projects
                </Link>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-7xl mx-auto">
          {/* Header */}
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-4">
              <Button variant="outline" asChild>
                <Link href="/projects">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Projects
                </Link>
              </Button>
              <div>
                <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {project?.fileName || 'Project'}
                </h1>
                <p className="text-slate-600 dark:text-slate-300">
                  {project?.extractedFileCount || 0} files
                </p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* File Tree */}
            <div className="lg:col-span-1">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">File Explorer</CardTitle>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                    <Input
                      type="text"
                      placeholder="Search files..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[600px]">
                    {filteredFiles.length === 0 ? (
                      <div className="text-center py-8 text-slate-500">
                        <File className="h-8 w-8 mx-auto mb-2" />
                        <p>No files found</p>
                      </div>
                    ) : (
                      renderFileTree(filteredFiles)
                    )}
                  </ScrollArea>
                </CardContent>
              </Card>
            </div>

            {/* File Content */}
            <div className="lg:col-span-2">
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-lg">
                        {selectedFile ? selectedFile.name : 'Select a file'}
                      </CardTitle>
                      <CardDescription>
                        {selectedFile && !selectedFile.isDirectory && (
                          `${(selectedFile.size / 1024).toFixed(1)} KB • ${new Date(selectedFile.lastModified).toLocaleString()}`
                        )}
                      </CardDescription>
                    </div>
                    
                    {selectedFile && !selectedFile.isDirectory && (
                      <div className="flex gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={saveFileContent}
                          disabled={saving}
                        >
                          {saving ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <Save className="h-4 w-4" />
                          )}
                          Save
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setSelectedFile(null)}
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  {loadingContent ? (
                    <div className="flex items-center justify-center h-96">
                      <div className="text-center">
                        <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
                        <p className="text-slate-600 dark:text-slate-300">Loading file content...</p>
                      </div>
                    </div>
                  ) : selectedFile ? (
                    selectedFile.isDirectory ? (
                      <div className="flex items-center justify-center h-96 text-slate-500">
                        <div className="text-center">
                          <FolderOpen className="h-16 w-16 mx-auto mb-4" />
                          <p className="text-lg">This is a directory</p>
                          <p className="text-sm">Select a file to view its content</p>
                        </div>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        <textarea
                          value={fileContent}
                          onChange={(e) => setFileContent(e.target.value)}
                          className="w-full h-96 p-4 border rounded-lg font-mono text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500"
                          placeholder="File content will appear here..."
                        />
                        <div className="flex items-center justify-between text-sm text-slate-500">
                          <span>{fileContent.length} characters</span>
                          <span>{fileContent.split('\n').length} lines</span>
                        </div>
                      </div>
                    )
                  ) : (
                    <div className="flex items-center justify-center h-96 text-slate-500">
                      <div className="text-center">
                        <FileText className="h-16 w-16 mx-auto mb-4" />
                        <p className="text-lg">Select a file to view</p>
                        <p className="text-sm">Click on a file from the explorer to view and edit its content</p>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}