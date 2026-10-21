<?php

declare(strict_types=1);

namespace Gnugat\Blog;

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\HttpKernel\Bundle\Bundle;

class TocBundle extends Bundle
{
    public function build(ContainerBuilder $container): void
    {
        $container->register(TocTwigExtension::class, TocTwigExtension::class)
            ->addTag('twig.extension');
    }
}
