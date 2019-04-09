/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.content;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.sql.SQLException;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.crosswalk.CrosswalkException;
import org.dspace.content.crosswalk.StreamDisseminationCrosswalk;
import org.dspace.core.Context;
import org.dspace.core.LogManager;
import org.dspace.core.PluginManager;

public class CitationMetadataUpdateProcessPlugin
        implements AdditionalMetadataUpdateProcessPlugin
{

    /** Logger */
    private static Logger log = Logger
            .getLogger(CitationMetadataUpdateProcessPlugin.class);

    private String schemaOutputMetadata;

    private String elementOutputMetadata;

    private String qualifierOutputMetadata;

    @Override
    public void process(Context context, Item item, String provider)
    {
        final StreamDisseminationCrosswalk streamCrosswalkDefault = (StreamDisseminationCrosswalk) PluginManager
                .getNamedPlugin(StreamDisseminationCrosswalk.class,
                        provider.trim() + ".citation");

        String type = item.getMetadata("dc.type");

        StreamDisseminationCrosswalk streamCrosswalk = null;
        if (StringUtils.isNotBlank(type))
        {
            streamCrosswalk = (StreamDisseminationCrosswalk) PluginManager
                    .getNamedPlugin(StreamDisseminationCrosswalk.class,
                            provider.trim() + "-"
                                    + StringUtils.deleteWhitespace(
                                            type.toLowerCase()).trim()
                            + ".citation");
        }

        if (streamCrosswalk == null)
        {
            streamCrosswalk = streamCrosswalkDefault;
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try
        {
            streamCrosswalk.disseminate(context, item, out);
            item.addMetadata(schemaOutputMetadata, elementOutputMetadata,
                    qualifierOutputMetadata, null, out.toString());
        }
        catch (Exception e)
        {
            log.error(LogManager.getHeader(context,
                    "citationMetadataUpdateProcessPlugin",
                    "item_id=" + item.getID()), e);
        }
    }

    public void setSchemaOutputMetadata(String schemaOutputMetadata)
    {
        this.schemaOutputMetadata = schemaOutputMetadata;
    }

    public void setElementOutputMetadata(String elementOutputMetadata)
    {
        this.elementOutputMetadata = elementOutputMetadata;
    }

    public void setQualifierOutputMetadata(String qualifierOutputMetadata)
    {
        this.qualifierOutputMetadata = qualifierOutputMetadata;
    }

}
