<?php

return [
    'jam_masuk' => env('ATTENDANCE_JAM_MASUK', '08:00'),
    'toleransi_menit' => (int) env('ATTENDANCE_TOLERANSI_MENIT', 5),
    'jam_pulang' => env('ATTENDANCE_JAM_PULANG', '16:00'),
    'biaya_lembur' => (int) env('ATTENDANCE_BIAYA_LEMBUR', 30000),
];
