#!/usr/bin/perl
# JSON-LD Article + FAQPage для статьи. FAQ берется из видимого текста content/{slug}.html,
# поэтому разметка всегда совпадает со страницей.
# perl tools/make-schema.pl slug "Заголовок H1" "Описание" > meta/slug.schema.json
use strict; use warnings; use utf8;
binmode STDOUT, ':encoding(UTF-8)';
my ($slug, $headline, $desc) = map { utf8::decode(my $s = $_); $s } @ARGV;
die "usage: slug headline description\n" unless $desc;
open my $in, '<:encoding(UTF-8)', "content/$slug.html" or die "no content/$slug.html";
local $/; my $html = <$in>; close $in;

sub clean { my $t = shift; $t =~ s/\{\{icon:[^}]+\}\}//g; $t =~ s/<[^>]+>//g; $t =~ s/\s+/ /g; $t =~ s/^\s+|\s+$//g; $t =~ s/\\/\\\\/g; $t =~ s/"/\\"/g; return $t; }

my @qa;
# Только вопросы FAQ: <details> без класса (мобильное оглавление имеет class="toc-mobile"),
# совпадение не выходит за границы одного вопроса.
while ($html =~ m#<details(?: open)?>\s*<summary>((?:(?!</summary>).)*?)</summary>\s*<p>((?:(?!</p>).)*)</p>\s*</details>#gs) { push @qa, [clean($1), clean($2)]; }

my $faq = join(",\n", map { qq(        { "\@type": "Question", "name": "$_->[0]", "acceptedAnswer": { "\@type": "Answer", "text": "$_->[1]" } }) } @qa);
$headline =~ s/"/\\"/g; $desc =~ s/"/\\"/g;
my $page = $slug eq 'home' ? '' : "$slug/";
print <<"JSON";
{
  "\@context": "https://schema.org",
  "\@graph": [
    {
      "\@type": "Article",
      "headline": "$headline",
      "description": "$desc",
      "inLanguage": "ru",
      "datePublished": "2026-10-20",
      "dateModified": "2026-10-20",
      "mainEntityOfPage": "{{DOMAIN}}/$page",
      "image": "{{DOMAIN}}/images/og-image.png",
      "author": { "\@id": "{{DOMAIN}}/#organization" },
      "publisher": { "\@id": "{{DOMAIN}}/#organization" }
    }@{[ @qa ? qq(,\n    {\n      "\@type": "FAQPage",\n      "mainEntity": [\n$faq\n      ]\n    }) : '' ]}
  ]
}
JSON
