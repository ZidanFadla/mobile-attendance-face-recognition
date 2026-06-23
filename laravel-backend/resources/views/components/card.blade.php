@props([
    'title' => null,
    'subtitle' => null,
])

<section {{ $attributes->class([
    'rounded-2xl border border-gray-200 bg-white p-6 shadow-sm',
]) }}>
    @if ($title || $subtitle || isset($icon))
        <div class="mb-6 flex items-start gap-3">
            @isset($icon)
                <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gray-100">
                    {{ $icon }}
                </div>
            @endisset

            <div>
                @if ($title)
                    <h2 class="text-lg font-semibold text-gray-900">{{ $title }}</h2>
                @endif

                @if ($subtitle)
                    <p class="mt-1 text-sm text-gray-500">{{ $subtitle }}</p>
                @endif
            </div>
        </div>
    @endif

    {{ $slot }}
</section>
