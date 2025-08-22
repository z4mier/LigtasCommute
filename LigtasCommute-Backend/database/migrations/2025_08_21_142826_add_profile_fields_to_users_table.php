<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Username (nullable + unique so you can add it later)
            if (!Schema::hasColumn('users', 'username')) {
                $table->string('username')->nullable()->unique()->after('email');
            }
            // Optional profile fields
            if (!Schema::hasColumn('users', 'phone')) {
                $table->string('phone', 32)->nullable()->after('username');
            }
            if (!Schema::hasColumn('users', 'location')) {
                $table->string('location', 255)->nullable()->after('phone');
            }
            // Points / prefs
            if (!Schema::hasColumn('users', 'points')) {
                $table->integer('points')->default(0)->after('location');
            }
            if (!Schema::hasColumn('users', 'language')) {
                $table->string('language', 5)->default('en')->after('points');
            }
            if (!Schema::hasColumn('users', 'dark_mode')) {
                $table->boolean('dark_mode')->default(false)->after('language');
            }
            // You already added is_verified/email_verified_at in older migrations
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'dark_mode'))  $table->dropColumn('dark_mode');
            if (Schema::hasColumn('users', 'language'))   $table->dropColumn('language');
            if (Schema::hasColumn('users', 'points'))     $table->dropColumn('points');
            if (Schema::hasColumn('users', 'location'))   $table->dropColumn('location');
            if (Schema::hasColumn('users', 'phone'))      $table->dropColumn('phone');

            // If your DB complains about dropping a unique column, you may need to drop the index name first:
            // $table->dropUnique('users_username_unique');
            if (Schema::hasColumn('users', 'username'))   $table->dropColumn('username');
        });
    }
};
