<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\FaceRecognitionController;
use App\Http\Controllers\AttendanceApiController;
use App\Http\Controllers\EmployeeAuthController;
use App\Http\Controllers\MessageApiController;
use App\Http\Controllers\RequestApiController;


Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/auth/register', [EmployeeAuthController::class, 'register']);
Route::post('/auth/login',    [EmployeeAuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/face/register', [FaceRecognitionController::class, 'registerFace']);
    Route::get('/face/check', [FaceRecognitionController::class, 'checkFace']);
    Route::get('/face/embeddings', [FaceRecognitionController::class, 'getEmbeddings']);
    Route::get('/attendance', [AttendanceApiController::class, 'index']);
    Route::post('/attendance', [AttendanceApiController::class, 'store']);
    Route::put('/profile', [EmployeeAuthController::class, 'updateProfile']);
    Route::post('/profile/photo', [EmployeeAuthController::class, 'uploadProfilePhoto']);
    Route::put('/profile/password', [EmployeeAuthController::class, 'changePassword']);

    // Messages (polling)
    Route::get('/messages', [MessageApiController::class, 'index']);
    Route::post('/messages/{message}/read', [MessageApiController::class, 'markOneRead']);
    Route::post('/messages/read', [MessageApiController::class, 'markRead']);

    // Leave and cash advance requests
    Route::get('/leave-balance', [RequestApiController::class, 'leaveBalance']);
    Route::get('/leave-requests', [RequestApiController::class, 'leaveIndex']);
    Route::post('/leave-requests', [RequestApiController::class, 'leaveStore']);
    Route::get('/cash-advance-summary', [RequestApiController::class, 'cashAdvanceSummary']);
    Route::get('/cash-advance-requests', [RequestApiController::class, 'cashAdvanceIndex']);
    Route::post('/cash-advance-requests', [RequestApiController::class, 'cashAdvanceStore']);
    Route::delete('/requests/{type}/{id}', [RequestApiController::class, 'cancel']);
});
