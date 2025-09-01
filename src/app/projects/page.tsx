"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { 
  FolderOpen, 
  FileText, 
  Calendar, 
  Trash2, 
  Download, 
  Search,
  Plus,
  ArrowLeft,
  Package,
  Loader2
} from "lucide-react"
import { toast } from "@/hooks/use-toast"
import Link from "next/link"

interface Project {
  id: string
  fileName: string
  uploadPath: string
  extractPath: string
  uploadedAt: string
  fileSize: number
  extractedFiles: string[]
  extractedFileCount: number
}

export default function ProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState("")
  const [deleting, setDeleting] = useState<string | null>(null)
  const [downloading, setDownloading] = useState<string | null>(null)

  useEffect(() => {
    loadProjects()
  }, [])

  const loadProjects = async () => {
    try {
      const response = await fetch('/api/projects')
      if (!response.ok) {
        throw new Error('Failed to load projects')
      }
      const data = await response.json()
      setProjects(data.files || [])
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to load projects",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const deleteProject = async (projectId: string) => {
    if (!confirm('Are you sure you want to delete this project? This action cannot be undone.')) {
      return
    }

    setDeleting(projectId)
    try {
      const response = await fetch(`/api/projects/${projectId}`, {
        method: 'DELETE',
      })

      if (!response.ok) {
        throw new Error('Failed to delete project')
      }

      setProjects(prev => prev.filter(p => p.id !== projectId))
      toast({
        title: "Success",
        description: "Project deleted successfully",
      })
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to delete project",
        variant: "destructive",
      })
    } finally {
      setDeleting(null)
    }
  }

  const downloadProject = async (projectId: string) => {
    setDownloading(projectId)
    try {
      const response = await fetch(`/api/projects/${projectId}/download`, {
        method: 'POST',
      })

      if (!response.ok) {
        throw new Error('Failed to download project')
      }

      // Get the blob from response
      const blob = await response.blob()
      
      // Create download link
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `project-${projectId}.zip`
      
      // Trigger download
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      
      // Clean up
      window.URL.revokeObjectURL(url)

      toast({
        title: "Success",
        description: "Project downloaded successfully",
      })
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to download project",
        variant: "destructive",
      })
    } finally {
      setDownloading(null)
    }
  }

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString()
  }

  const filteredProjects = projects.filter(project =>
    project.fileName.toLowerCase().includes(searchTerm.toLowerCase())
  )

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-slate-600 dark:text-slate-300">Loading projects...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-6xl mx-auto">
          {/* Header */}
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-4">
              <Button variant="outline" asChild>
                <Link href="/">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Upload
                </Link>
              </Button>
              <div>
                <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  Projects
                </h1>
                <p className="text-slate-600 dark:text-slate-300">
                  Manage your uploaded code projects
                </p>
              </div>
            </div>
            <Button asChild>
              <Link href="/">
                <Plus className="h-4 w-4 mr-2" />
                Upload New Project
              </Link>
            </Button>
          </div>

          {/* Search Bar */}
          <div className="mb-6">
            <div className="relative max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input
                type="text"
                placeholder="Search projects..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>

          {/* Projects Grid */}
          {filteredProjects.length === 0 ? (
            <Card>
              <CardContent className="flex flex-col items-center justify-center py-12">
                <FolderOpen className="h-12 w-12 text-slate-400 mb-4" />
                <h3 className="text-lg font-medium text-slate-900 dark:text-slate-100 mb-2">
                  {searchTerm ? 'No projects found' : 'No projects yet'}
                </h3>
                <p className="text-slate-600 dark:text-slate-300 text-center mb-4">
                  {searchTerm 
                    ? 'Try adjusting your search terms'
                    : 'Upload your first project to get started'
                  }
                </p>
                {!searchTerm && (
                  <Button asChild>
                    <Link href="/">
                      <Plus className="h-4 w-4 mr-2" />
                      Upload Project
                    </Link>
                  </Button>
                )}
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredProjects.map((project) => (
                <Card key={project.id} className="hover:shadow-lg transition-shadow">
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <div className="flex-1 min-w-0">
                        <CardTitle className="text-lg truncate" title={project.fileName}>
                          {project.fileName}
                        </CardTitle>
                        <CardDescription className="text-sm">
                          {formatFileSize(project.fileSize)}
                        </CardDescription>
                      </div>
                      <Badge variant="secondary" className="ml-2">
                        {project.extractedFileCount} files
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <div className="flex items-center text-sm text-slate-600 dark:text-slate-300">
                        <Calendar className="h-4 w-4 mr-2" />
                        {formatDate(project.uploadedAt)}
                      </div>
                      
                      <div className="flex items-center text-sm text-slate-600 dark:text-slate-300">
                        <FileText className="h-4 w-4 mr-2" />
                        {project.extractedFileCount} files extracted
                      </div>

                      <div className="flex gap-2 pt-2">
                        <Button asChild className="flex-1">
                          <Link href={`/projects/${project.id}`}>
                            <FolderOpen className="h-4 w-4 mr-2" />
                            Browse
                          </Link>
                        </Button>
                        
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => downloadProject(project.id)}
                          disabled={downloading === project.id}
                        >
                          {downloading === project.id ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <Package className="h-4 w-4" />
                          )}
                        </Button>
                        
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => deleteProject(project.id)}
                          disabled={deleting === project.id}
                        >
                          {deleting === project.id ? (
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-red-600"></div>
                          ) : (
                            <Trash2 className="h-4 w-4" />
                          )}
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Stats */}
          {projects.length > 0 && (
            <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-4">
              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-600 dark:text-slate-300">
                        Total Projects
                      </p>
                      <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                        {projects.length}
                      </p>
                    </div>
                    <FolderOpen className="h-8 w-8 text-blue-600" />
                  </div>
                </CardContent>
              </Card>
              
              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-600 dark:text-slate-300">
                        Total Files
                      </p>
                      <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                        {projects.reduce((sum, p) => sum + p.extractedFileCount, 0)}
                      </p>
                    </div>
                    <FileText className="h-8 w-8 text-green-600" />
                  </div>
                </CardContent>
              </Card>
              
              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-600 dark:text-slate-300">
                        Total Size
                      </p>
                      <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                        {formatFileSize(projects.reduce((sum, p) => sum + p.fileSize, 0))}
                      </p>
                    </div>
                    <Download className="h-8 w-8 text-purple-600" />
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}