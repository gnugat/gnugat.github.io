<?php

declare(strict_types=1);

use Gnugat\Blog\TocBundle;
use Sculpin\Bundle\SculpinBundle\HttpKernel\AbstractKernel;

class SculpinKernel extends AbstractKernel
{
    protected function getAdditionalSculpinBundles(): array
    {
        return [TocBundle::class];
    }
}
