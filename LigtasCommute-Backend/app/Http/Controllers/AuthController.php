<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Models\User;

class AuthController extends Controller
{
    // -------- Register --------
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'     => ['required','string','max:255'],
            'email'    => ['required','string','email','max:255','unique:users,email'],
            'password' => ['required','string','min:6'],
            'phone'    => ['required','string','max:15'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed','errors' => $validator->errors()], 422);
        }

        $user = User::create([
            'name'        => $request->name,
            'email'       => strtolower($request->email),
            'phone'       => $request->phone,
            'role'        => 'commuter',
            'is_verified' => 0,
            'password'    => Hash::make($request->password),
        ]);

        app(\App\Http\Controllers\OtpController::class)->sendOtp(new Request(['email' => $user->email]));

        return response()->json([
            'message' => 'User registered successfully. Please verify the OTP sent to your email.',
            'email'   => $user->email,
        ], 201);
    }

    // -------- Login --------
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email'    => ['required','string','email'],
            'password' => ['required','string'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed','errors' => $validator->errors()], 422);
        }

        $email = strtolower($request->email);
        $user  = User::where('email', $email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $isVerified = !empty($user->is_verified) && (int)$user->is_verified === 1;
        if (!$isVerified) {
            return response()->json([
                'requires_verification' => true,
                'message'               => 'Please verify the OTP sent to your email.',
            ], 200);
        }

        $token = $user->createToken('api')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token'   => $token,
            'user'    => $user,
        ], 200);
    }

    // -------- Forgot Password (OTP) --------
    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        app(\App\Http\Controllers\OtpController::class)->sendOtp(
            new Request(['email' => strtolower($request->email)])
        );
        return response()->json(['message' => 'Reset OTP sent to your email'], 200);
    }

    // -------- Current User (GET /api/user) --------
    public function user(Request $request)
    {
        $u = $request->user();

        return response()->json([
            'id'         => $u->id,
            'name'       => $u->name,
            'email'      => $u->email,
            'phone'      => $u->phone ?? null,
            'location'   => $u->location ?? null,
            'role'       => $u->role ?? 'commuter',
            'is_verified'=> (int)($u->is_verified ?? 0),
            'points'     => (int)($u->points ?? 0),
            'created_at' => optional($u->created_at)->toISOString(),
            'updated_at' => optional($u->updated_at)->toISOString(),
            // 'username' => $u->username ?? null, // include if you need it on client
        ], 200);
    }

    // -------- Update Profile (PATCH /api/user) --------
    public function updateProfile(Request $request)
    {
        $u = $request->user();

        $validator = Validator::make($request->all(), [
            'name'     => ['required','string','max:255'],
            'email'    => ['required','email','max:255','unique:users,email,'.$u->id],
            'phone'    => ['nullable','string','max:20'],
            'location' => ['nullable','string','max:255'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed','errors' => $validator->errors()], 422);
        }

        $u->name     = $request->name;
        $u->email    = strtolower($request->email);
        $u->phone    = $request->phone;
        $u->location = $request->location;
        $u->save();

        return response()->json($u, 200);
    }

    // -------- Update Username (POST /api/user/username) --------
    public function updateUsername(Request $request)
    {
        $u = $request->user();

        $validator = Validator::make($request->all(), [
            'current_username' => ['required','string'],
            'new_username'     => ['required','string','min:8','regex:/^[A-Za-z0-9_]+$/','unique:users,username,'.$u->id],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed','errors' => $validator->errors()], 422);
        }

        // Ensure your users table has a 'username' column
        if (($u->username ?? null) !== $request->current_username) {
            return response()->json(['message' => 'Current username does not match'], 422);
        }

        $u->username = $request->new_username;
        $u->save();

        return response()->json(['message' => 'Username updated'], 200);
    }

    // -------- Update Password (POST /api/user/password) --------
    public function updatePassword(Request $request)
    {
        $u = $request->user();

        $validator = Validator::make($request->all(), [
            'current_password' => ['required','string'],
            'new_password'     => ['required','string','min:8'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed','errors' => $validator->errors()], 422);
        }

        if (!Hash::check($request->current_password, $u->password)) {
            return response()->json(['message' => 'Current password is incorrect'], 422);
        }

        $u->password = Hash::make($request->new_password);
        $u->save();

        return response()->json(['message' => 'Password updated'], 200);
    }

    // -------- Logout (POST /api/logout) --------
    public function logout(Request $request)
    {
        $user = $request->user();
        if ($user && $user->currentAccessToken()) {
            $user->currentAccessToken()->delete();
        }
        return response()->json(['message' => 'Logged out'], 200);
    }
}


