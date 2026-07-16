@props(['value'])

<label {{ $attributes->merge(['class' => 'block text-sm font-bold text-slate-700']) }}>
    {{ $value ?? $slot }}
</label>
