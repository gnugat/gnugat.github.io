<?php

declare(strict_types=1);

namespace Gnugat\Blog;

use Twig\Extension\AbstractExtension;
use Twig\TwigFilter;

class TocTwigExtension extends AbstractExtension
{
    public function getFilters(): array
    {
        return [new TwigFilter('toc', [$this, 'toc'], ['is_safe' => ['html']])];
    }

    /**
     * Builds a nested list from rendered HTML: h3 under the preceding h2.
     *
     * Sculpin renders layouts once before page.blocks exists, hence the nullable HTML.
     */
    public function toc(?string $html): string
    {
        preg_match_all('#<h([23]) id="([^"]+)">(.*?)</h\1>#s', $html ?? '', $headings, PREG_SET_ORDER);

        $sections = [];
        foreach ($headings as [, $level, $id, $title]) {
            $link = '<a href="#'.$id.'">'.strip_tags($title).'</a>';
            if ('2' === $level || [] === $sections) {
                $sections[] = ['link' => $link, 'children' => []];

                continue;
            }
            $sections[array_key_last($sections)]['children'][] = $link;
        }

        $list = '';
        foreach ($sections as $section) {
            $sublist = implode('', array_map(
                static fn (string $link): string => "<li>{$link}</li>",
                $section['children'],
            ));
            $list .= '<li>'.$section['link'].('' === $sublist ? '' : "<ul>{$sublist}</ul>").'</li>';
        }

        return "<ul>{$list}</ul>";
    }
}
