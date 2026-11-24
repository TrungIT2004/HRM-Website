# Face Attendance System - Validation Report

*Generated on: 2026-11-22*

## 1. Face Recognition (face_recognition/dlib)

- **Model**: face_recognition (dlib) - 128-dim encodings
- **Tolerance**: 0.6
- **Detector**: HOG (CPU)
- **Resolution**: 320x240

## 2. Anti-Spoofing (ONNX)

- **Model**: `src/cascades/anti_spoof.onnx` (FP32, 128x128 input)
- **Preprocessing**: Letterbox resize + reflect padding + normalize [0,1]
- **Threshold**: 0.55 antispoof_score
- **Spoof types detected**: Print, Replay (Pad/Phone), Masks
- **Known weakness**: PC Replay (~50% detection) - training data gap (Protocol 1 has 0 PC Replay samples)

## 3. Cooldowns

| Cooldown | Duration | Purpose |
|----------|----------|---------|
| Per-user recognition | 3s | Prevent duplicate clock_in/out |
| Spoof detection | 5s | Prevent audio spam on persistent attacks |
| Global event | 4s | Skip heavy processing after any event |
| Audio playback | ~2.5s | Hardware limit (pygame.mixer.Sound allows overlap) |

## 4. Audio System

- **Engine**: pygame.mixer.Sound (supports overlapping playback)
- **New**: `spoof_detected.mp3` (dedicated spoof alert, ~2s)
- **Overlapping**: Multiple clock_in sounds can play simultaneously

## 5. Processing Pipeline

- **Capture**: 320x240 @ 30fps continuous
- **Processing**: Every 3 seconds (PROCESS_INTERVAL)
- **Anti-spoof**: Runs on each processed frame
- **Recognition**: 128-dim dlib encodings, tolerance=0.6
- **Global cooldown**: 4s skip after any event

## 6. Known Limitations

- **PC Replay weakness**: ~50% detection rate (training data gap)
- **HOG detector**: Slower than CNN/YuNet, less accurate on angled faces
- **Resolution**: 320x240 limits face detail for recognition
- **dlib encodings**: 128-dim vs modern 512-dim (ArcFace)

## 7. Recommendations

1. **Fix PC Replay**: Retrain with Protocol 2 data (26,827 PC Replay samples)
2. **Upgrade detector**: YuNet or CNN for better accuracy/speed
3. **Upgrade recognition**: ArcFace 512-dim for better accuracy
4. **Increase resolution**: 640x480 for better face detail