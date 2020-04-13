#! /usr/bin/env python                        
                                          
import imapdedup                   
                         
class options:                   
    server = 'localhost'
    port = 1143
    ssl = False
    user = 'daffyduke@protonmail.com'
    password = 'tbdViGon5vulf2NL_3VRPw'
    verbose = False
    dry_run = False
    use_checksum = True
    use_id_in_checksum = True
    just_list = False
    no_close = False
    process = False

mboxes = [
        'Inbox',
        'A_Garder',
        'Concerts',
        'Copains',
        'Copains.Amis',
        'Copains.Chevillards',
        'Copains.CopainsDuNord',
        'Copains.Famille',
        'Copains.GrandMix',
        'Copains.NordList',
        'Copains.Sociaux',
        'LautreNet',
        'LautreNet.Aide',
        'LautreNet.Altern',
        'LautreNet.AlternC-dev',
        'LautreNet.Assemblee',
        'LautreNet.charte',
        'LautreNet.CollegeSolidaire',
        'LautreNet.contact',
        'LautreNet.Debats',
        'LautreNet.FDN',
        'LautreNet.Globenet',
        'LautreNet.HebergementAssociatif',
        'LautreNet.LEN',
        'LautreNet.RIHA',
        'LautreNet.root',
        'LautreNet.root.admin', 
        'LautreNet.root.postmaster', 
        'LautreNet.root.suppressions',
        'LautreNet.root.Warnings',
        'LautreNet.Techos',
        'Listes',
        'Listes.CitQuot',
        'Listes.CyberUnix',
        'Listes.Emploi',
        'Listes.Indymedia',
        'Listes.Lapin',
        'Listes.LiensUtiles',
        'Listes.MurphyListe',
        'Listes.Mygale',
        'Listes.Publicites',
        'Listes.RaslFront',
        'Listes.Samizdat',
        'Listes.STPresse',
        'Listes.UnixLibres',
        'Listes.ViePrivee',
        'LogicielsLibres',
        'LogicielsLibres.AFUL',
        'LogicielsLibres.ANIS',
        'LogicielsLibres.APRIL',
        'LogicielsLibres.BxLUG',
        'LogicielsLibres.CLX-bureau',
        'LogicielsLibres.CLX-liste',
        'LogicielsLibres.CLX-manifs',
        'LogicielsLibres.CLX-web',
        'LogicielsLibres.Conf&AOk-rence',
        'LogicielsLibres.CRDP',
        'LogicielsLibres.Difdall-CA',
        'LogicielsLibres.Difdall-Opic',
        'LogicielsLibres.FSF-europe',
        'LogicielsLibres.grenouille',
        'LogicielsLibres.InterLUG',
        'LogicielsLibres.RMLLs',
        'LogicielsLibres.SolutionLinux',
        'LogicielsLibres.SPIP',
        'LogicielsLibres.Virus',
        'Mailspring',
        'Mailspring.Snoozed',
        'Sent',
        'Travail',
        'Travail.Atos',
        'Travail.Atos.Systeme',
        'Travail.Atos.Systeme.FRSAG',
        'Travail.Atos.Systeme.Securite',
        'Travail.Techsys',

    ]

imapdedup.process(options, mboxes)