# Configuration
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFolder,  # The folder containing source videos
    [string]$OutputFolder = "processed\videos",  # Output folder relative to input folder
    [string]$ThumbnailsFolder = "processed\thumbnails"  # Thumbnails folder relative to input folder
)

$config = @{
    InputFolder = $InputFolder
    OutputFolder = Join-Path $InputFolder $OutputFolder
    ThumbnailsFolder = Join-Path $InputFolder $ThumbnailsFolder
    HandBrakePath = "D:\HandBrakeCLI\HandBrakeCLI.exe"  # Update this path
    FFmpegPath = "D:\HandBrakeCLI\ffmpeg\ffmpeg-2025-08-14-git-cdbb5f1b93-full_build\bin\ffmpeg.exe"  # Update this path
    DefaultDuration = 2  # Default duration in seconds
    Quality = 20  # HandBrake quality (lower = better, 18-28 recommended)
    VideoWidth = 720  # Target width for HD videos
    FrameRate = 30  # Target frame rate
}

# Video configuration
$videoConfig = @{
    "DumbellBentOverRows.mp4" = @{
        TaskName = "bent_rows"
        Duration = 2
        StartTime = 0
    }
    "DumbellLateralRaise.mp4" = @{
        TaskName = "side_lifts"
        Duration = 2
        StartTime = 0
    }
    "DumbellShoulderPress.mp4" = @{
        TaskName = "shoulder_exercise"
        Duration = 2
        StartTime = 0
    }
    "DumbellSquats.mp4" = @{
        TaskName = "squats"
        Duration = 2
        StartTime = 0
    }
    "JogInPlace.mp4" = @{
        TaskName = "walking"
        Duration = 2
        StartTime = 0
    }
    "Pushups.mp4" = @{
        TaskName = "pushups"
        Duration = 2
        StartTime = 0
    }
    "BicycleCrunch.mp4" = @{
        TaskName = "stretches"
        Duration = 2
        StartTime = 0
    }
    "JumpingJacks.mp4" = @{
        TaskName = "dancing"
        Duration = 2
        StartTime = 0
    }
    "HipRaises.mp4" = @{
        TaskName = "hoola_hooping"  # Using hip raises as alternative for hoola hooping
        Duration = 2
        StartTime = 0
    }
    "LateralRaise.mp4" = @{
        TaskName = "tricep_stretches"  # Using lateral raise as temporary replacement
        Duration = 2
        StartTime = 0
    }
    "Girl running on treadmill.mp4" = @{
        TaskName = "nature"  # Using treadmill video temporarily for nature
        Duration = 2
        StartTime = 0
    }
    "Burpees.mp4" = @{
        TaskName = "burpees"  # Additional exercise
        Duration = 2
        StartTime = 0
    }
    "DonkeyKicks.mp4" = @{
        TaskName = "donkey_kicks"  # Additional exercise
        Duration = 2
        StartTime = 0
    }
    "LegRaises.mp4" = @{
        TaskName = "leg_raises"  # Additional exercise
        Duration = 2
        StartTime = 0
    }
    "Lunge.mp4" = @{
        TaskName = "lunges"  # Additional exercise
        Duration = 2
        StartTime = 0
    }
    "SideLegRaises.mp4" = @{
        TaskName = "side_leg_raises"  # Additional exercise
        Duration = 2
        StartTime = 0
    }
}

# Validate paths and create directories
if (-not (Test-Path $config.InputFolder)) {
    Write-Host "ERROR: Input folder not found: $($config.InputFolder)"
    exit 1
}
if (-not (Test-Path $config.HandBrakePath)) {
    Write-Host "ERROR: HandBrakeCLI not found at $($config.HandBrakePath)"
    exit 1
}
if (-not (Test-Path $config.FFmpegPath)) {
    Write-Host "ERROR: FFmpeg not found at $($config.FFmpegPath)"
    exit 1
}

# Create output directories
Write-Host "Creating output directories..."
New-Item -ItemType Directory -Force -Path $config.OutputFolder | Out-Null
New-Item -ItemType Directory -Force -Path $config.ThumbnailsFolder | Out-Null

# Function to process video
function Process-Video {
    param (
        [string]$inputFile,
        [string]$taskName,
        [int]$duration,
        [int]$startTime
    )

    $inputPath = Join-Path $config.InputFolder $inputFile
    $outputFile = "${taskName}.mp4"
    $outputPath = Join-Path $config.OutputFolder $outputFile
    $thumbnailFile = "${taskName}.jpg"
    $thumbnailPath = Join-Path $config.ThumbnailsFolder $thumbnailFile

    Write-Host "`nProcessing $inputFile for task $taskName..."
    Write-Host "Input: $inputPath"
    Write-Host "Output: $outputPath"

    if (-not (Test-Path $inputPath)) {
        Write-Host "ERROR: Input file not found: $inputPath"
        return
    }

    # Compress and trim video using HandBrake with better quality settings
    Write-Host "Compressing and trimming video..."
    $handbrakeArgs = @(
        "-i", $inputPath,
        "-o", $outputPath,
        "--start-at", "seconds:$startTime",
        "--stop-at", "seconds:$($startTime + $duration)",
        "-e", "x264",
        "-q", $config.Quality,
        "-w", $config.VideoWidth,
        "--height", "0",
        "--keep-display-aspect",
        "--rate", $config.FrameRate,
        "--pfr",
        "-b", "2500",
        "--optimize",
        "--encoder-preset", "medium",  # Changed from slower for better performance
        "--encoder-profile", "high",
        "--encoder-level", "4.2",
        "--preset", "Fast 1080p30"  # Changed preset for better reliability
    )
    
    $result = & $config.HandBrakePath $handbrakeArgs 2>&1
    
    if (-not (Test-Path $outputPath)) {
        Write-Host "ERROR: Failed to process video"
        Write-Host $result
        return
    }

    # Extract thumbnail using FFmpeg with proper aspect ratio
    try {
        Write-Host "Generating thumbnail for $taskName..."
        
        # Simple direct thumbnail generation with auto-calculated dimensions
        $ffmpegArgs = @(
            "-i", $outputPath,
            "-ss", "0.5",
            "-frames:v", "1",
            "-filter:v", "scale=w=320:h=-1",
            "-y",
            $thumbnailPath
        )
        
        # Execute FFmpeg and capture all output
        $output = & $config.FFmpegPath $ffmpegArgs 2>&1
        
        if (-not (Test-Path $thumbnailPath)) {
            Write-Host "ERROR: Failed to generate thumbnail for $taskName"
            Write-Host "FFmpeg output:"
            Write-Host $output
            Write-Host "Command used:"
            Write-Host "$($config.FFmpegPath) $($ffmpegArgs -join ' ')"
        } else {
            Write-Host "Successfully generated thumbnail: $thumbnailPath"
        }
        
        Write-Host "Generating thumbnail..."
        $result = & $config.FFmpegPath $ffmpegArgs 2>&1
        
        if (-not (Test-Path $thumbnailPath)) {
            Write-Host "ERROR: Failed to generate thumbnail"
            Write-Host $result
        }
    }
    catch {
        Write-Host "ERROR: Failed to generate thumbnail"
        Write-Host $_.Exception.Message
    }

    Write-Host "Completed processing $inputFile"
    Write-Host "Output: $outputPath"
    Write-Host "Thumbnail: $thumbnailPath"
    Write-Host "---------------------------"
}

# Process each video
foreach ($video in $videoConfig.GetEnumerator()) {
    Process-Video `
        -inputFile $video.Key `
        -taskName $video.Value.TaskName `
        -duration $video.Value.Duration `
        -startTime $video.Value.StartTime
}

# Generate video configuration JSON for Flutter app
$flutterConfig = $videoConfig.GetEnumerator() | ForEach-Object {
    @{
        taskName = $_.Value.TaskName
        videoPath = "assets/videos/$($_.Value.TaskName).mp4"
        thumbnailPath = "assets/thumbnails/$($_.Value.TaskName).jpg"
        duration = $_.Value.Duration
    }
} | ConvertTo-Json

$configPath = Join-Path $config.OutputFolder "..\video_config.json"
Set-Content -Path $configPath -Value $flutterConfig

Write-Host "`nVideo processing complete!"
Write-Host "Generated files in:"
Write-Host "Videos: $($config.OutputFolder)"
Write-Host "Thumbnails: $($config.ThumbnailsFolder)"
Write-Host "Config: $configPath"
Write-Host "`nTo use in Flutter app:"
Write-Host "1. Copy the processed folders to your assets directory"
Write-Host "2. Add the following to your pubspec.yaml:"
Write-Host "assets:"
Write-Host "  - assets/videos/"
Write-Host "  - assets/thumbnails/"
Write-Host "  - assets/video_config.json"
