@props([
    'title' => null,
    'subtitle' => null,
])

<section {{ $attributes->class([
    'clay-panel p-6 sm:p-7 transition-all duration-300 hover:-translate-y-0.5',
]) }}>
    @if ($title || $subtitle || isset($icon))
        <div class="mb-6 flex items-start gap-4">
            @isset($icon)
                <div class="icon-tile text-[#4F8EF7]">
                    {{ $icon }}
                </div>
            @endisset

            <div class="min-w-0">
                @if ($title)
                    <h2 class="text-lg font-black tracking-tight text-slate-900">{{ $title }}</h2>
                @endif

                @if ($subtitle)
                    <p class="mt-1 text-sm font-medium leading-6 text-slate-500">{{ $subtitle }}</p>
                @endif
            </div>
        </div>
    @endif

    {{ $slot }}
</section>
