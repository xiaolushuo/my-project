"use client"

import { useState, useCallback } from "react"
import { useDropzone } from "react-dropzone"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { Upload, FileText, CheckCircle, AlertCircle, Loader2 } from "lucide-react"
import { toast } from "@/hooks/use-toast"

interface UploadState {
  isUploading: boolean
  uploadProgress: number
  uploadStatus: "idle" | "uploading" | "success" | "error"
  fileName: string | null
  fileSize: number | null
  errorMessage: string | null
}

export default function Home() {
  const [uploadState, setUploadState] = useState<UploadState>({
    isUploading: false,
    uploadProgress: 0,
    uploadStatus: "idle",
    fileName: null,
    fileSize: null,
    errorMessage: null,
  })

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    const file = acceptedFiles[0]
    if (!file) return

    // Check if file is a zip file
    if (!file.name.toLowerCase().endsWith('.zip')) {
      toast({
        title: "Invalid file type",
        description: "Please upload a .zip file containing your code.",
        variant: "destructive",
      })
      return
    }

    // Check file size (limit to 100MB)
    const maxSize = 100 * 1024 * 1024 // 100MB
    if (file.size > maxSize) {
      toast({
        title: "File too large",
        description: "Please upload a file smaller than 100MB.",
        variant: "destructive",
      })
      return
    }

    setUploadState({
      isUploading: true,
      uploadProgress: 0,
      uploadStatus: "uploading",
      fileName: file.name,
      fileSize: file.size,
      errorMessage: null,
    })

    try {
      const formData = new FormData()
      formData.append('file', file)

      // Simulate upload progress
      const progressInterval = setInterval(() => {
        setUploadState(prev => {
          if (prev.uploadProgress >= 90) {
            clearInterval(progressInterval)
            return prev
          }
          return { ...prev, uploadProgress: prev.uploadProgress + 10 }
        })
      }, 200)

      const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      })

      clearInterval(progressInterval)

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Upload failed')
      }

      const result = await response.json()
      
      setUploadState(prev => ({
        ...prev,
        isUploading: false,
        uploadProgress: 100,
        uploadStatus: "success",
      }))

      toast({
        title: "Upload successful",
        description: `Your code has been uploaded and extracted successfully.`,
      })

      console.log('Upload result:', result)

    } catch (error) {
      setUploadState(prev => ({
        ...prev,
        isUploading: false,
        uploadStatus: "error",
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
      }))

      toast({
        title: "Upload failed",
        description: error instanceof Error ? error.message : "Failed to upload file",
        variant: "destructive",
      })
    }
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/zip': ['.zip'],
    },
    multiple: false,
    disabled: uploadState.isUploading,
  })

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const resetUpload = () => {
    setUploadState({
      isUploading: false,
      uploadProgress: 0,
      uploadStatus: "idle",
      fileName: null,
      fileSize: null,
      errorMessage: null,
    })
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold tracking-tight text-slate-900 dark:text-slate-100 mb-4">
              Code Upload Portal
            </h1>
            <p className="text-lg text-slate-600 dark:text-slate-300">
              Upload your code package to get started with development
            </p>
          </div>

          <Card className="mb-6">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Upload className="h-5 w-5" />
                Upload Code Package
              </CardTitle>
              <CardDescription>
                Upload a .zip file containing your project code. The file will be extracted and ready for development.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div
                {...getRootProps()}
                className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
                  isDragActive
                    ? 'border-blue-500 bg-blue-50 dark:bg-blue-950'
                    : uploadState.isUploading
                    ? 'border-slate-300 bg-slate-50 dark:bg-slate-800 cursor-not-allowed'
                    : 'border-slate-300 hover:border-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
                }`}
              >
                <input {...getInputProps()} />
                
                {uploadState.uploadStatus === "idle" && (
                  <div className="space-y-4">
                    <div className="mx-auto w-12 h-12 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center">
                      <FileText className="h-6 w-6 text-slate-500" />
                    </div>
                    <div>
                      <p className="text-lg font-medium text-slate-900 dark:text-slate-100">
                        {isDragActive ? "Drop your zip file here" : "Drag & drop your zip file here"}
                      </p>
                      <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                        or click to browse files
                      </p>
                    </div>
                    <div className="flex flex-wrap justify-center gap-2">
                      <Badge variant="outline">.zip files only</Badge>
                      <Badge variant="outline">Max 100MB</Badge>
                    </div>
                  </div>
                )}

                {uploadState.uploadStatus === "uploading" && (
                  <div className="space-y-4">
                    <div className="mx-auto w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                      <Loader2 className="h-6 w-6 text-blue-600 dark:text-blue-400 animate-spin" />
                    </div>
                    <div>
                      <p className="text-lg font-medium text-slate-900 dark:text-slate-100">
                        Uploading {uploadState.fileName}
                      </p>
                      <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                        {formatFileSize(uploadState.fileSize!)}
                      </p>
                    </div>
                    <div className="space-y-2">
                      <Progress value={uploadState.uploadProgress} className="w-full" />
                      <p className="text-sm text-slate-500 dark:text-slate-400">
                        {uploadState.uploadProgress}% complete
                      </p>
                    </div>
                  </div>
                )}

                {uploadState.uploadStatus === "success" && (
                  <div className="space-y-4">
                    <div className="mx-auto w-12 h-12 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center">
                      <CheckCircle className="h-6 w-6 text-green-600 dark:text-green-400" />
                    </div>
                    <div>
                      <p className="text-lg font-medium text-slate-900 dark:text-slate-100">
                        Upload Complete!
                      </p>
                      <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                        {uploadState.fileName} has been uploaded and extracted successfully
                      </p>
                    </div>
                    <div className="flex gap-2 justify-center">
                      <Button onClick={resetUpload} variant="outline">
                        Upload Another File
                      </Button>
                      <Button asChild>
                        <a href="/projects">
                          View Projects
                        </a>
                      </Button>
                    </div>
                  </div>
                )}

                {uploadState.uploadStatus === "error" && (
                  <div className="space-y-4">
                    <div className="mx-auto w-12 h-12 bg-red-100 dark:bg-red-900 rounded-full flex items-center justify-center">
                      <AlertCircle className="h-6 w-6 text-red-600 dark:text-red-400" />
                    </div>
                    <div>
                      <p className="text-lg font-medium text-slate-900 dark:text-slate-100">
                        Upload Failed
                      </p>
                      <p className="text-sm text-red-600 dark:text-red-400 mt-1">
                        {uploadState.errorMessage}
                      </p>
                    </div>
                    <Button onClick={resetUpload} variant="outline">
                      Try Again
                    </Button>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Instructions</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 text-sm text-slate-600 dark:text-slate-300">
                <div className="flex items-start gap-2">
                  <span className="font-medium">1.</span>
                  <span>Compress your project code into a .zip file</span>
                </div>
                <div className="flex items-start gap-2">
                  <span className="font-medium">2.</span>
                  <span>Ensure the zip file contains your project structure</span>
                </div>
                <div className="flex items-start gap-2">
                  <span className="font-medium">3.</span>
                  <span>Upload the file using the interface above</span>
                </div>
                <div className="flex items-start gap-2">
                  <span className="font-medium">4.</span>
                  <span>Once uploaded, your code will be extracted and ready for development</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}