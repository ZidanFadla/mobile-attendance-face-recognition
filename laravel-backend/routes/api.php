<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\FaceRecognitionController;
use App\Http\Controllers\AttendanceApiController;
use App\Http\Controllers\EmployeeAuthController;
use App\Http\Controllers\MessageApiController;


Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/auth/register', [EmployeeAuthController::class, 'register']);
Route::post('/auth/login',    [EmployeeAuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/face/register', [FaceRecognitionController::class, 'registerFace']);
    Route::post('/face/verify', [FaceRecognitionController::class, 'verifyFace']);
    Route::get('/face/check', [FaceRecognitionController::class, 'checkFace']);
    Route::post('/attendance', [AttendanceApiController::class, 'store']);
    Route::post('/face/register-multiple', [FaceRecognitionController::class, 'registerFaceMultiple']);

    // Messages (polling)
    Route::get('/messages', [MessageApiController::class, 'index']);
    Route::post('/messages/{message}/read', [MessageApiController::class, 'markOneRead']);
    Route::post('/messages/read', [MessageApiController::class, 'markRead']);
});
