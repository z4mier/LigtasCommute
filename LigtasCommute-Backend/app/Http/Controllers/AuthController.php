<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * Register new commuter
     * - Creates user as unverified
     * - Immediately sends OTP email
     */
    public function register(Request $request)
    {
        // Validate input
        $validator = Validator::make($request->all(), [
            'name'     => ['required','string','max:255'],
            'email'    => ['required','string','email','max:255','unique:users,email'],
            'password' => ['required','string','min:6'],
            'phone'    => ['required','string','max:15'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        // Create user (unverified by default)
        $user = User::create([
            'name'        => $request->name,
            'email'       => strtolower($request->email),
            'phone'       => $request->phone,
            'role'        => 'commuter',
            'is_verified' => 0,
            'password'    => Hash::make($request->password),
        ]);

        // ✅ Send OTP immediately after signup
        app(\App\Http\Controllers\OtpController::class)->sendOtp(
            new Request(['email' => $user->email])
        );

        return response()->json([
            'message' => 'User registered successfully. Please verify the OTP sent to your email.',
            'email'   => $user->email,
        ], 201);
    }

    /**
     * Login commuter
     * - Unverified user → ask client to verify via OTP (no token)
     * - Verified user   → issue Sanctum token
     */
    public function login(Request $request)
    {
        // Validate input
        $validator = Validator::make($request->all(), [
            'email'    => ['required','string','email'],
            'password' => ['required','string'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        // Fetch user & verify password
        $email = strtolower($request->email);
        $user  = User::where('email', $email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // If NOT verified → tell client to go to OTP flow
        $isVerified = !empty($user->is_verified) && (int)$user->is_verified === 1;
        if (!$isVerified) {
            // (We don't auto-send here because your OTP screen already calls /send-otp on load.
            // If you prefer auto-send from login too, call OtpController::sendOtp like in register.)
            return response()->json([
                'requires_verification' => true,
                'message'               => 'Please verify the OTP sent to your email.',
            ], 200);
        }

        // Verified → issue Sanctum token
        $token = $user->createToken('api')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'token'   => $token,
            'user'    => $user,
        ], 200);
    }

    /**
     * Forgot password
     * - Reuses the same OTP sending logic
     */
    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        app(\App\Http\Controllers\OtpController::class)->sendOtp(
            new Request(['email' => strtolower($request->email)])
        );

        return response()->json(['message' => 'Reset OTP sent to your email'], 200);
    }
}
