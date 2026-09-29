{#
    Single source of truth for the preventive care quality measures mart.

    Each measure declares its denominator criteria (age at performance period end, sex) and the
    concepts that drive its numerator and exclusions. Concepts carry the codes that qualify plus:

      lookback_months   Months before the performance period begin that an event may fall in.
                        0 = performance period only, null = any history through period end.
      min_age_at_event  Minimum patient age on the date of the event for it to count (optional).

    Code systems match the Tuva core normalized code types ('hcpcs', 'icd-10-cm', 'icd-10-pcs')
    plus 'revenue_center' for medical claim revenue codes. ICD codes are stored without dots.

    Code lists are a curated subset of the NCQA HEDIS / CMS eCQM value sets that cover what is
    typically billed on claims; they are not a licensed, complete value set.
#}

{% macro preventive_care_hospice_concept() %}
    {{ return({
        'concept_name': 'hospice services',
        'value_set_type': 'exclusion',
        'lookback_months': 0,
        'min_age_at_event': none,
        'codes': {
            'hcpcs': [
                'G9473', 'G9474', 'G9475', 'G9476', 'G9477', 'G9478', 'G9479', 'G9687',
                'Q5003', 'Q5004', 'Q5005', 'Q5006', 'Q5007', 'Q5008', 'Q5010',
                'S9126', 'T2042', 'T2043', 'T2044', 'T2045', 'T2046'
            ],
            'revenue_center': [
                '0115', '0125', '0135', '0145', '0155', '0235',
                '0650', '0651', '0652', '0655', '0656', '0657', '0658', '0659'
            ]
        }
    }) }}
{% endmacro %}


{% macro preventive_care_measure_definitions() %}

    {% set hospice = preventive_care_hospice_concept() %}

    {% set measures = [
        {
            'measure_id': 'BCS',
            'measure_name': 'Breast Cancer Screening',
            'steward': 'NCQA',
            'reference_specification': 'HEDIS BCS-E / CMS125',
            'description': 'Women 52-74 who had a mammogram to screen for breast cancer between October 1 two years prior to the performance period and the end of the performance period.',
            'min_age': 52,
            'max_age': 74,
            'required_sex': 'female',
            'concepts': [
                {
                    'concept_name': 'mammography',
                    'value_set_type': 'numerator',
                    'lookback_months': 15,
                    'min_age_at_event': none,
                    'codes': {
                        'hcpcs': ['77061', '77062', '77063', '77065', '77066', '77067', 'G0202', 'G0204', 'G0206']
                    }
                },
                {
                    'concept_name': 'bilateral mastectomy',
                    'value_set_type': 'exclusion',
                    'lookback_months': none,
                    'min_age_at_event': none,
                    'codes': {
                        'icd-10-cm': ['Z9013'],
                        'icd-10-pcs': ['0HTV0ZZ']
                    }
                },
                {
                    'concept_name': 'unilateral mastectomy left',
                    'value_set_type': 'exclusion',
                    'lookback_months': none,
                    'min_age_at_event': none,
                    'codes': {
                        'icd-10-cm': ['Z9012'],
                        'icd-10-pcs': ['0HTU0ZZ']
                    }
                },
                {
                    'concept_name': 'unilateral mastectomy right',
                    'value_set_type': 'exclusion',
                    'lookback_months': none,
                    'min_age_at_event': none,
                    'codes': {
                        'icd-10-cm': ['Z9011'],
                        'icd-10-pcs': ['0HTT0ZZ']
                    }
                },
                hospice
            ]
        },
        {
            'measure_id': 'CCS',
            'measure_name': 'Cervical Cancer Screening',
            'steward': 'NCQA',
            'reference_specification': 'HEDIS CCS-E / CMS124',
            'description': 'Women 24-64 screened for cervical cancer: cervical cytology within the last 3 years (age 21+ at test) or high-risk HPV testing within the last 5 years (age 30+ at test).',
            'min_age': 24,
            'max_age': 64,
            'required_sex': 'female',
            'concepts': [
                {
                    'concept_name': 'cervical cytology',
                    'value_set_type': 'numerator',
                    'lookback_months': 24,
                    'min_age_at_event': 21,
                    'codes': {
                        'hcpcs': [
                            '88141', '88142', '88143', '88147', '88148', '88150', '88152', '88153',
                            '88164', '88165', '88166', '88167', '88174', '88175',
                            'G0123', 'G0124', 'G0141', 'G0143', 'G0144', 'G0145', 'G0147', 'G0148',
                            'P3000', 'P3001', 'Q0091'
                        ]
                    }
                },
                {
                    'concept_name': 'high-risk hpv test',
                    'value_set_type': 'numerator',
                    'lookback_months': 48,
                    'min_age_at_event': 30,
                    'codes': {
                        'hcpcs': ['87624', '87625', 'G0476']
                    }
                },
                {
                    'concept_name': 'hysterectomy with no residual cervix',
                    'value_set_type': 'exclusion',
                    'lookback_months': none,
                    'min_age_at_event': none,
                    'codes': {
                        'icd-10-cm': ['Z90710', 'Z90712', 'Q515'],
                        'icd-10-pcs': ['0UTC0ZZ', '0UTC4ZZ', '0UTC7ZZ', '0UTC8ZZ'],
                        'hcpcs': [
                            '51925', '56308', '57540', '57545', '57550', '57555', '57556',
                            '58150', '58152', '58200', '58210', '58240', '58260', '58262', '58263',
                            '58267', '58270', '58275', '58280', '58285', '58290', '58291', '58292',
                            '58293', '58294', '58548', '58550', '58552', '58553', '58554', '58570',
                            '58571', '58572', '58573', '58951', '58953', '58954', '58956', '59135'
                        ]
                    }
                },
                hospice
            ]
        },
        {
            'measure_id': 'COL',
            'measure_name': 'Colorectal Cancer Screening',
            'steward': 'NCQA',
            'reference_specification': 'HEDIS COL-E / CMS130',
            'description': 'Adults 46-75 with appropriate colorectal cancer screening: colonoscopy (10 years), flexible sigmoidoscopy or CT colonography (5 years), stool DNA with FIT (3 years) or FOBT (performance period).',
            'min_age': 46,
            'max_age': 75,
            'required_sex': none,
            'concepts': [
                {
                    'concept_name': 'colonoscopy',
                    'value_set_type': 'numerator',
                    'lookback_months': 108,
                    'min_age_at_event': none,
                    'codes': {
                        'hcpcs': [
                            '44388', '44389', '44390', '44391', '44392', '44394', '44401', '44402',
                            '44403', '44404', '44405', '44406', '44407', '44408',
                            '45378', '45379', '45380', '45381', '45382', '45384', '45385', '45386',
                            '45388', '45389', '45390', '45391', '45392', '45393', '45398',
                            'G0105', 'G0121'
                        ]
                    }
                },
                {
                    'concept_name': 'flexible sigmoidoscopy',
                    'value_set_type': 'numerator',
                    'lookback_months': 48,
                    'min_age_at_event': none,
                    'codes': {
                        'hcpcs': [
                            '45330', '45331', '45332', '45333', '45334', '45335', '45337', '45338',
                            '45340', '45341', '45342', '45346', '45347', '45349', '45350', 'G0104'
                        ]
                    }
                },
                {
                    'concept_name': 'ct colonography',
                    'value_set_type': 'numerator',
                    'lookback_months': 48,
                    'min_age_at_event': none,
                    'codes': {
                        'hcpcs': ['74261', '74262', '74263']
                    }
                },
                {
                    'concept_name': 'stool dna with fit test',
                    'value_set_type': 'numerator',
                    'lookback_months': 24,
                    'min_age_at_event': none,
                    'codes': {
                        'hcpcs': ['81528', 'G0464']
                    }
                },
                {
                    'concept_name': 'fecal occult blood test',
                    'value_set_type': 'numerator',
                    'lookback_months': 0,
                    'min_age_at_event': none,
                    'codes': {
                        'hcpcs': ['82270', '82274', 'G0328']
                    }
                },
                {
                    'concept_name': 'colorectal cancer',
                    'value_set_type': 'exclusion',
                    'lookback_months': none,
                    'min_age_at_event': none,
                    'codes': {
                        'icd-10-cm': [
                            'C180', 'C181', 'C182', 'C183', 'C184', 'C185', 'C186', 'C187', 'C188', 'C189',
                            'C19', 'C20', 'C212', 'C218', 'C785', 'Z85038', 'Z85048'
                        ]
                    }
                },
                {
                    'concept_name': 'total colectomy',
                    'value_set_type': 'exclusion',
                    'lookback_months': none,
                    'min_age_at_event': none,
                    'codes': {
                        'icd-10-pcs': ['0DTE0ZZ', '0DTE4ZZ', '0DTE7ZZ', '0DTE8ZZ'],
                        'hcpcs': ['44150', '44151', '44155', '44156', '44157', '44158', '44210', '44211', '44212']
                    }
                },
                hospice
            ]
        }
    ] %}

    {{ return(measures) }}

{% endmacro %}
