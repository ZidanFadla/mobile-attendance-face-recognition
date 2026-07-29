<?php

namespace App\Http\Controllers;

use App\Models\EmployeeDeviceToken;
use Illuminate\Http\Request;

class NotificationTokenController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['nullable', 'string', 'max:32'],
        ]);

        EmployeeDeviceToken::updateOrCreate(
            ['token' => $validated['token']],
            [
                'employee_id' => $request->user()->id,
                'platform' => $validated['platform'] ?? null,
                'last_used_at' => now(),
            ]
        );

        return response()->json(['success' => true]);
    }

    public function destroy(Request $request)
    {
        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        EmployeeDeviceToken::where('employee_id', $request->user()->id)
            ->where('token', $validated['token'])
            ->delete();

        return response()->json(['success' => true]);
    }
}